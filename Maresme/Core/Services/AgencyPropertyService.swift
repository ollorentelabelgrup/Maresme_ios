import Foundation

struct AgencyPropertyService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // GET /api/v1/agency/properties
    // status: nil = todos, "draft" | "active" | "reserved" | "sold"
    func list(status: String? = nil, cursor: String? = nil) async throws -> CursorPage<AgencyProperty> {
        var query: [URLQueryItem] = []
        if let status { query.append(.init(name: "status", value: status)) }
        if let cursor { query.append(.init(name: "cursor", value: cursor)) }
        return try await client.request(
            Endpoint(.get, "/agency/properties", query: query.isEmpty ? nil : query)
        )
    }

    // GET /api/v1/agency/properties/{slug}
    func detail(slug: String) async throws -> AgencyPropertyDetail {
        let wrapped: WrappedResponse<AgencyPropertyDetail> = try await client.request(
            Endpoint(.get, "/agency/properties/\(slug)")
        )
        return wrapped.data
    }

    // GET /api/v1/agency/properties/{slug}/leads
    func leads(slug: String, status: String? = nil, cursor: String? = nil) async throws -> CursorPage<AgencyLead> {
        var query: [URLQueryItem] = []
        if let status { query.append(.init(name: "status", value: status)) }
        if let cursor { query.append(.init(name: "cursor", value: cursor)) }
        return try await client.request(
            Endpoint(.get, "/agency/properties/\(slug)/leads", query: query.isEmpty ? nil : query)
        )
    }

    // GET /api/v1/agency/stats
    func stats() async throws -> AgencyStats {
        let wrapped: WrappedResponse<AgencyStats> = try await client.request(
            Endpoint(.get, "/agency/stats")
        )
        return wrapped.data
    }
}
