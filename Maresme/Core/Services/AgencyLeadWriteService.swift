import Foundation

struct AgencyLeadWriteService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // PATCH /api/v1/agency/leads/{id}
    // Accepts: status?, lead_quality?, buyer_stage?
    func update(
        leadId: Int,
        status: String? = nil,
        leadQuality: String? = nil,
        buyerStage: String? = nil
    ) async throws -> AgencyLeadDetail {
        struct Payload: Encodable {
            let status:      String?
            let leadQuality: String?
            let buyerStage:  String?
            enum CodingKeys: String, CodingKey {
                case status
                case leadQuality = "lead_quality"
                case buyerStage  = "buyer_stage"
            }
        }
        let wrapped: WrappedResponse<AgencyLeadDetail> = try await client.request(
            Endpoint(.patch, "/agency/leads/\(leadId)", body: Payload(
                status:      status,
                leadQuality: leadQuality,
                buyerStage:  buyerStage
            ))
        )
        return wrapped.data
    }

    // POST /api/v1/agency/leads/{id}/notes
    func addNote(leadId: Int, note: String) async throws -> AgencyLeadNote {
        struct Payload: Encodable { let note: String }
        struct Response: Decodable { let data: AgencyLeadNote }
        let response: Response = try await client.request(
            Endpoint(.post, "/agency/leads/\(leadId)/notes", body: Payload(note: note))
        )
        return response.data
    }

    // POST /api/v1/agency/leads/{id}/assign
    func assign(leadId: Int, userId: Int) async throws -> AgencyLeadDetail {
        struct Payload: Encodable {
            let userId: Int
            enum CodingKeys: String, CodingKey { case userId = "user_id" }
        }
        let wrapped: WrappedResponse<AgencyLeadDetail> = try await client.request(
            Endpoint(.post, "/agency/leads/\(leadId)/assign", body: Payload(userId: userId))
        )
        return wrapped.data
    }
}
