import Foundation

struct AlertService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // GET /api/v1/alerts — full list (non-paginated)
    func list() async throws -> [AlertModel] {
        let wrapped: WrappedResponse<[AlertModel]> = try await client.request(
            Endpoint(.get, "/alerts")
        )
        return wrapped.data
    }

    // GET /api/v1/alerts/{id}
    func show(id: Int) async throws -> AlertModel {
        let wrapped: WrappedResponse<AlertModel> = try await client.request(
            Endpoint(.get, "/alerts/\(id)")
        )
        return wrapped.data
    }

    // POST /api/v1/alerts  → 201
    func create(request: CreateAlertRequest) async throws -> AlertModel {
        let wrapped: WrappedResponse<AlertModel> = try await client.request(
            Endpoint(.post, "/alerts", body: request)
        )
        return wrapped.data
    }

    // PATCH /api/v1/alerts/{id}
    func update(id: Int, request: UpdateAlertRequest) async throws -> AlertModel {
        let wrapped: WrappedResponse<AlertModel> = try await client.request(
            Endpoint(.patch, "/alerts/\(id)", body: request)
        )
        return wrapped.data
    }

    // DELETE /api/v1/alerts/{id}
    func delete(id: Int) async throws {
        try await client.requestVoid(Endpoint(.delete, "/alerts/\(id)"))
    }

    // POST /api/v1/alerts/{id}/pause
    func pause(id: Int) async throws -> AlertModel {
        let wrapped: WrappedResponse<AlertModel> = try await client.request(
            Endpoint(.post, "/alerts/\(id)/pause")
        )
        return wrapped.data
    }

    // POST /api/v1/alerts/{id}/resume
    func resume(id: Int) async throws -> AlertModel {
        let wrapped: WrappedResponse<AlertModel> = try await client.request(
            Endpoint(.post, "/alerts/\(id)/resume")
        )
        return wrapped.data
    }

    // GET /api/v1/alerts/{id}/matches  (cursor-paginated PropertyCard)
    func matches(id: Int, cursor: String? = nil) async throws -> CursorPage<PropertyCard> {
        var query: [URLQueryItem] = []
        if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
        return try await client.request(
            Endpoint(.get, "/alerts/\(id)/matches", query: query.isEmpty ? nil : query)
        )
    }
}
