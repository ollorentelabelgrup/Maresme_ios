import Foundation
import Observation

@Observable
final class ProfessionalDashboardViewModel {
    var stats:           AgencyStats?       = nil
    var trends:          AgencyStatsTrends? = nil
    var recentActivity:  [AgencyActivity]   = []
    var isLoading:       Bool               = true
    var errorMessage:    String?            = nil

    private let propertyService = AgencyPropertyService()
    private let activityService = AgencyActivityService()

    func load() async {
        guard isLoading else { return }
        errorMessage = nil
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadStats() }
            group.addTask { await self.loadTrends() }
            group.addTask { await self.loadActivity() }
        }
        isLoading = false
    }

    func reload() async {
        isLoading    = true
        errorMessage = nil
        await load()
    }

    // MARK: - Private loaders

    private func loadStats() async {
        do {
            stats = try await propertyService.stats()
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
    }

    private func loadTrends() async {
        trends = try? await propertyService.trends()
    }

    private func loadActivity() async {
        if let page = try? await activityService.feed() {
            recentActivity = Array(page.data.prefix(5))
        }
    }
}
