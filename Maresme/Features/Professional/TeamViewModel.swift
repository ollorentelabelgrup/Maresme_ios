import Foundation
import Observation

@Observable
final class TeamViewModel {
    var members:      [AgencyTeamMember] = []
    var isLoading:    Bool               = true
    var errorMessage: String?            = nil

    private let service = AgencyTeamService()

    func load() async {
        guard isLoading else { return }
        errorMessage = nil
        do {
            members = try await service.list()
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    func reload() async {
        isLoading    = true
        errorMessage = nil
        await load()
    }
}
