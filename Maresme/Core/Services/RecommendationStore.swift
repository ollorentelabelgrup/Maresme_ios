import Foundation

// Lightweight store — solo contadores para badges y HomeView widget.
// La lista paginada vive en RecommendationsViewModel (como FavoriteStore/FavoritesViewModel).
@Observable
final class RecommendationStore {
    var totalCount:    Int  = 0
    var unviewedCount: Int  = 0
    var highScoreCount: Int = 0
    var isLoaded:      Bool = false

    private let service: RecommendationService

    init(service: RecommendationService = RecommendationService()) {
        self.service = service
    }

    func loadCount() async {
        do {
            let response   = try await service.count()
            totalCount     = response.count
            unviewedCount  = response.unviewed
            highScoreCount = response.highScore
            isLoaded       = true
        } catch {
            // No crítico — badges quedan en cero si falla
        }
    }

    func reset() {
        totalCount     = 0
        unviewedCount  = 0
        highScoreCount = 0
        isLoaded       = false
    }
}
