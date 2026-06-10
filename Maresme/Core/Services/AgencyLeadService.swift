import Foundation

struct AgencyLeadService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // GET /api/v1/agency/leads
    // status: nil = todos | "new" | "contacted" | "qualified" | "converted" | "closed"
    func list(status: String? = nil, cursor: String? = nil) async throws -> CursorPage<AgencyLead> {
        var query: [URLQueryItem] = []
        if let status { query.append(.init(name: "status", value: status)) }
        if let cursor { query.append(.init(name: "cursor", value: cursor)) }
        return try await client.request(
            Endpoint(.get, "/agency/leads", query: query.isEmpty ? nil : query)
        )
    }

    // GET /api/v1/agency/leads/{id}
    func detail(id: Int) async throws -> AgencyLeadDetail {
        let wrapped: WrappedResponse<AgencyLeadDetail> = try await client.request(
            Endpoint(.get, "/agency/leads/\(id)")
        )
        return wrapped.data
    }
}
