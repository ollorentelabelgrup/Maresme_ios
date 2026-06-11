import Foundation

struct PropertyService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // GET /api/v1/properties
    // Soporta paginación dual: cursor (featured/newest) u offset por página (price_asc/price_desc).
    // Para price_asc/price_desc el backend usa LengthAwarePaginator → pasar page: Int.
    // Para el resto usa CursorPaginator → pasar cursor: String.
    func list(
        filters: PropertySearchFilters = PropertySearchFilters(),
        cursor:  String? = nil,
        page:    Int?    = nil
    ) async throws -> PropertyListResponse {
        var query = filters.toQueryItems()
        if let cursor { query.append(.init(name: "cursor", value: cursor)) }
        if let page   { query.append(.init(name: "page",   value: "\(page)")) }
        return try await client.request(
            Endpoint(.get, "/properties", query: query.isEmpty ? nil : query)
        )
    }

    // GET /api/v1/properties/featured
    // Returns up to 10 featured PropertyCard (no pagination, cached 15 min).
    func featured() async throws -> [PropertyCard] {
        // Backend returns a ResourceCollection → { "data": [...] }
        let wrapped: WrappedResponse<[PropertyCard]> = try await client.request(
            Endpoint(.get, "/properties/featured")
        )
        return wrapped.data
    }

    // GET /api/v1/properties/{slug}
    func detail(slug: String) async throws -> PropertyDetail {
        let wrapped: WrappedResponse<PropertyDetail> = try await client.request(
            Endpoint(.get, "/properties/\(slug)")
        )
        return wrapped.data
    }
}
