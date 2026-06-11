import Foundation

struct NotificationService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // GET /api/v1/notifications  (cursor-paginated, 20 items/page)
    func list(cursor: String? = nil) async throws -> CursorPage<AppNotification> {
        var query: [URLQueryItem] = []
        if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
        return try await client.request(
            Endpoint(.get, "/notifications", query: query.isEmpty ? nil : query)
        )
    }

    // GET /api/v1/notifications/count → { "total": N, "unread": N }
    func count() async throws -> NotificationCountResponse {
        try await client.request(Endpoint(.get, "/notifications/count"))
    }

    // GET /api/v1/notifications/{id}
    func show(id: Int) async throws -> AppNotification {
        let wrapped: WrappedResponse<AppNotification> = try await client.request(
            Endpoint(.get, "/notifications/\(id)")
        )
        return wrapped.data
    }

    // POST /api/v1/notifications/{id}/read
    func markRead(id: Int) async throws {
        try await client.requestVoid(Endpoint(.post, "/notifications/\(id)/read"))
    }

    // POST /api/v1/notifications/read-all
    func markAllRead() async throws {
        try await client.requestVoid(Endpoint(.post, "/notifications/read-all"))
    }

    // DELETE /api/v1/notifications/{id}
    func delete(id: Int) async throws {
        try await client.requestVoid(Endpoint(.delete, "/notifications/\(id)"))
    }
}
