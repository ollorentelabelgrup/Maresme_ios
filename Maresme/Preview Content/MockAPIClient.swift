import Foundation

// MockAPIClient allows SwiftUI previews and unit tests to inject
// a fake network layer without hitting the real backend.
//
// Usage in #Preview:
//   AuthService(client: MockAPIClient.loggedIn)
//
// NOTE: MockAPIClient is NOT an actor — it wraps APIClient to satisfy
// the same interface. For full mock flexibility, extract a protocol in MB-8+.

actor MockAPIClient {
    // Shared instances for common preview scenarios
    static let loggedIn = MockAPIClient(
        token: "mock-sanctum-token-preview"
    )
    static let loggedOut = MockAPIClient(token: nil)

    private let token: String?

    init(token: String?) {
        self.token = token
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        throw APIError.server(statusCode: 501, message: "MockAPIClient: not implemented for \(endpoint.path)")
    }

    func requestVoid(_ endpoint: Endpoint) async throws {
        // No-op in mock
    }
}

// MARK: - Preview SessionManager factory

extension SessionManager {
    static func previewAuthenticated() -> SessionManager {
        let session = SessionManager()
        session.signIn(token: "preview-token", user: PreviewData.user)
        return session
    }

    static func previewUnauthenticated() -> SessionManager {
        SessionManager()
    }
}
