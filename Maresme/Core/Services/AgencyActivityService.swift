import Foundation

struct AgencyActivityService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // GET /api/v1/agency/activity
    func feed(cursor: String? = nil) async throws -> CursorPage<AgencyActivity> {
        var query: [URLQueryItem] = []
        if let cursor { query.append(.init(name: "cursor", value: cursor)) }
        return try await client.request(
            Endpoint(.get, "/agency/activity", query: query.isEmpty ? nil : query)
        )
    }
}
