import Foundation

@Observable
final class FavoritesViewModel {
    var favorites:    [FavoriteModel] = []
    var isLoading:    Bool            = false
    var isLoadingMore: Bool           = false
    var errorMessage: String?         = nil
    var hasMore:      Bool            = true

    private var nextCursor: String?  = nil
    private let service: FavoriteService

    init(service: FavoriteService = FavoriteService()) {
        self.service = service
    }

    func loadInitial() async {
        guard !isLoading else { return }
        isLoading    = true
        errorMessage = nil
        nextCursor   = nil
        hasMore      = true

        do {
            let page  = try await service.list(cursor: nil)
            favorites  = page.data
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
            favorites.append(contentsOf: page.data)
            nextCursor = page.nextCursor
            hasMore    = page.nextCursor != nil
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isLoadingMore = false
    }

    func refresh() async {
        await loadInitial()
    }

    // Slugs of all loaded favorites — used to seed FavoriteStore
    var loadedSlugs: [String] {
        favorites.map(\.property.slug)
    }
}
