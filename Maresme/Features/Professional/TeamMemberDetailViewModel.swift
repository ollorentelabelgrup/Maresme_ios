import Foundation
import Observation

@Observable
final class TeamMemberDetailViewModel {
    var member:       AgencyTeamMember? = nil
    var isLoading:    Bool              = false
    var errorMessage: String?           = nil

    private let service = AgencyTeamService()

    func load(userId: Int) async {
        isLoading    = true
        errorMessage = nil
        do {
            member = try await service.member(userId: userId)
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
