import Foundation

actor APIClient {
    // nonisolated(unsafe): SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor would make this @MainActor.
    // It is set once at app launch and never mutated — safe to access from any context.
    nonisolated(unsafe) static let shared = APIClient()

    // ISO8601DateFormatter is not Sendable. Stored as static nonisolated(unsafe) so they can
    // be referenced inside the @Sendable dateDecodingStrategy closure without capture warnings.
    private nonisolated(unsafe) static let isoWithMs: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private nonisolated(unsafe) static let isoWithoutMs: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let tokenProvider: () -> String?

    init(tokenProvider: @escaping () -> String? = { KeychainService.getToken() }) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 60
        self.session       = URLSession(configuration: config)
        self.tokenProvider = tokenProvider

        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        // Carbon's toISOString() returns 6 fractional digits (microseconds), e.g. "2026-06-10T07:30:53.116553Z".
        // ISO8601DateFormatter.withFractionalSeconds reliably handles only 3. We normalize in the closure below.
        dec.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            var str       = try container.decode(String.self)
            // PHP Carbon's toISOString() may emit 6 fractional digits (microseconds):
            // "2026-06-10T09:30:00.000000Z". ISO8601DateFormatter withFractionalSeconds
            // reliably handles only 3 digits. Normalize by keeping the first 3.
            if let dotIdx = str.firstIndex(of: ".") {
                let afterDot = str.index(after: dotIdx)
                var fracEnd  = afterDot
                while fracEnd < str.endIndex && str[fracEnd].isNumber {
                    fracEnd = str.index(after: fracEnd)
                }
                let fracCount = str.distance(from: afterDot, to: fracEnd)
                if fracCount > 3 {
                    str.removeSubrange(str.index(afterDot, offsetBy: 3)..<fracEnd)
                }
            }
            if let date = APIClient.isoWithMs.date(from: str)    { return date }
            if let date = APIClient.isoWithoutMs.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(str)"
            )
        }
        self.decoder = dec
    }

    // MARK: - Generic request

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let urlRequest = try buildRequest(endpoint)
        let (data, response) = try await performRequest(urlRequest)
        try validate(response: response, data: data)
        return try decode(T.self, from: data)
    }

    func requestVoid(_ endpoint: Endpoint) async throws {
        let urlRequest = try buildRequest(endpoint)
        let (data, response) = try await performRequest(urlRequest)
        try validate(response: response, data: data)
    }

    // MARK: - Multipart upload (for photo uploads)

    func uploadMultipart<T: Decodable>(_ path: String, boundary: String, body: Data) async throws -> T {
        guard let url = URLComponents(
            url: Config.apiBaseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )?.url else {
            throw APIError.unknown
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body

        let (data, response) = try await performRequest(request)
        try validate(response: response, data: data)
        return try decode(T.self, from: data)
    }

    // MARK: - Build

    private func buildRequest(_ endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(
            url: Config.apiBaseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        )

        if let query = endpoint.queryItems, !query.isEmpty {
            components?.queryItems = query
        }

        guard let url = components?.url else {
            throw APIError.unknown
        }

        var request        = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // encodedBody is Data? (pre-encoded by Endpoint.init) — no @MainActor cross-isolation
        if let body = endpoint.encodedBody {
            request.httpBody = body
        }

        return request
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }
            return (data, httpResponse)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network(underlying: error)
        }
    }

    // MARK: - Validate

    private func validate(response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 422:
            if let errorResponse = try? decoder.decode(ValidationErrorResponse.self, from: data) {
                throw APIError.validation(
                    message: errorResponse.message,
                    errors:  errorResponse.errors ?? [:]
                )
            }
            throw APIError.unknown
        default:
            let message = (try? decoder.decode(MessageResponse.self, from: data))?.message ?? "Error del servidor."
            throw APIError.server(statusCode: response.statusCode, message: message)
        }
    }

    // MARK: - Decode

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            #if DEBUG
            print("[APIClient] ❌ Decode failed for \(T.self)")
            print("[APIClient] Error: \(error)")
            print("[APIClient] Raw JSON: \(String(data: data, encoding: .utf8) ?? "<non-UTF8>")")
            #endif
            throw APIError.decoding(underlying: error)
        }
    }
}

// MARK: - Endpoint

struct Endpoint {
    let method:      HTTPMethod
    let path:        String
    let queryItems:  [URLQueryItem]?
    let encodedBody: Data?   // pre-encoded JSON; avoids @MainActor cross-isolation from (any Encodable)?

    init(
        _ method: HTTPMethod,
        _ path: String,
        query: [URLQueryItem]? = nil,
        body: (any Encodable)? = nil
    ) {
        self.method      = method
        self.path        = path
        self.queryItems  = query
        // Encode on the @MainActor call site, store as plain Sendable Data
        self.encodedBody = body.flatMap { try? JSONEncoder().encode($0) }
    }
}
