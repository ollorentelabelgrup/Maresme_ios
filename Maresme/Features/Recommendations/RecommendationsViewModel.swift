import Foundation

@Observable
final class RecommendationsViewModel {
    var items:          [Recommendation] = []
    var isLoading:      Bool             = false
    var isLoadingMore:  Bool             = false
    var hasMore:        Bool             = true
    var errorMessage:   String?          = nil
    var isRefreshing:   Bool             = false
    var refreshMessage: String?          = nil

    private var nextCursor: String?           = nil
    private let service:    RecommendationService
    private let store:      RecommendationStore

    init(service: RecommendationService = RecommendationService(), store: RecommendationStore) {
        self.service = service
        self.store   = store
    }

    // MARK: - Load

    func loadIfNeeded() async {
        guard items.isEmpty else { return }
        await load()
    }

    func load() async {
        guard !isLoading else { return }
        isLoading    = true
        errorMessage = nil
        nextCursor   = nil
        hasMore      = true

        do {
            let page   = try await service.list(cursor: nil)
            items      = page.data
            nextCursor = page.nextCursor
            hasMore    = page.nextCursor != nil
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoading, !isLoadingMore, let cursor = nextCursor else { return }
        isLoadingMore = true

        do {
            let page = try await service.list(cursor: cursor)
            items.append(contentsOf: page.data)
            nextCursor = page.nextCursor
            hasMore    = page.nextCursor != nil
        } catch {
            // silencioso en paginación
        }
        isLoadingMore = false
    }

    // MARK: - Refresh

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing   = true
        refreshMessage = nil
        errorMessage   = nil

        do {
            let result = try await service.refresh()
            refreshMessage = result.generated > 0
                ? "\(result.generated) nuevas recomendaciones generadas"
                : "Recomendaciones actualizadas"
            await store.loadCount()
            await load()
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isRefreshing = false
    }
}
