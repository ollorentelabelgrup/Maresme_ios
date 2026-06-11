import Foundation

struct RecommendationService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // GET /api/v1/recommendations?cursor=...
    // Cursor paginated, auth required (score >= 65, ordenado por score desc)
    func list(cursor: String? = nil) async throws -> CursorPage<Recommendation> {
        var query: [URLQueryItem] = []
        if let cursor {
            query.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return try await client.request(
            Endpoint(.get, "/recommendations", query: query.isEmpty ? nil : query)
        )
    }

    // GET /api/v1/recommendations/count
    // Devuelve count, unviewed, high_score — usado para badges e HomeView
    func count() async throws -> RecommendationCountResponse {
        try await client.request(Endpoint(.get, "/recommendations/count"))
    }

    // GET /api/v1/recommendations/{slug}
    // Respuesta: { "data": { "matching": {...}, "property": PropertyDetailResource } }
    // Marca viewed_at en la primera visita (reduce badge unviewed)
    func show(slug: String) async throws -> RecommendationDetail {
        let wrapped: WrappedResponse<RecommendationDetail> = try await client.request(
            Endpoint(.get, "/recommendations/\(slug)")
        )
        return wrapped.data
    }

    // POST /api/v1/recommendations/refresh
    // Fuerza el recálculo del motor de matching para el usuario autenticado
    func refresh() async throws -> RecommendationRefreshResponse {
        try await client.request(Endpoint(.post, "/recommendations/refresh"))
    }
}
