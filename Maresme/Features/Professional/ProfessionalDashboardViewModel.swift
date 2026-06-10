import Foundation
import Observation

@Observable
final class ProfessionalDashboardViewModel {
    var stats:        AgencyStats? = nil
    var isLoading:    Bool         = true
    var errorMessage: String?      = nil

    private let service = AgencyPropertyService()

    func load() async {
        guard isLoading else { return }
        errorMessage = nil
        do {
            stats = try await service.stats()
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
