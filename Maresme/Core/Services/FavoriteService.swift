import Foundation

struct FavoriteService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // GET /api/v1/favorites?cursor=...
    func list(cursor: String? = nil) async throws -> CursorPage<FavoriteModel> {
        var query: [URLQueryItem] = []
        if let cursor {
            query.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return try await client.request(
            Endpoint(.get, "/favorites", query: query.isEmpty ? nil : query)
        )
    }

    // GET /api/v1/favorites/count
    func count() async throws -> Int {
        let response: FavoriteCountResponse = try await client.request(
            Endpoint(.get, "/favorites/count")
        )
        return response.count
    }

    // POST /api/v1/favorites/{slug}/toggle
    func toggle(slug: String) async throws -> FavoriteActionResponse {
        return try await client.request(
            Endpoint(.post, "/favorites/\(slug)/toggle")
        )
    }

    // POST /api/v1/favorites/{slug} — añadir
    func add(slug: String) async throws -> FavoriteActionResponse {
        return try await client.request(
            Endpoint(.post, "/favorites/\(slug)")
        )
    }

    // DELETE /api/v1/favorites/{slug} — eliminar
    func remove(slug: String) async throws -> FavoriteActionResponse {
        return try await client.request(
            Endpoint(.delete, "/favorites/\(slug)")
        )
    }
}
