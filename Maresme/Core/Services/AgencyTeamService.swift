import Foundation

struct AgencyTeamService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // GET /api/v1/agency/team
    func list() async throws -> [AgencyTeamMember] {
        let wrapped: WrappedResponse<[AgencyTeamMember]> = try await client.request(
            Endpoint(.get, "/agency/team")
        )
        return wrapped.data
    }

    // GET /api/v1/agency/team/{userId}
    func member(userId: Int) async throws -> AgencyTeamMember {
        let wrapped: WrappedResponse<AgencyTeamMember> = try await client.request(
            Endpoint(.get, "/agency/team/\(userId)")
        )
        return wrapped.data
    }
}
