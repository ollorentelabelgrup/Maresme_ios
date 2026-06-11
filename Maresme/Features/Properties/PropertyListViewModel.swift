import Foundation

@Observable
final class PropertyListViewModel {
    var properties:    [PropertyCard] = []
    var isLoading:     Bool           = false
    var isLoadingMore: Bool           = false
    var errorMessage:  String?        = nil
    var hasMore:       Bool           = true

    private var nextCursor:     String?           = nil
    private var nextPage:       Int?              = nil
    private var currentFilters: PropertySearchFilters = PropertySearchFilters()

    private let service: PropertyService

    init(service: PropertyService = PropertyService()) {
        self.service = service
    }

    // MARK: - Load

    func loadInitial(filters: PropertySearchFilters = PropertySearchFilters()) async {
        guard !isLoading else { return }
        currentFilters = filters
        properties     = []    // limpia antes de mostrar LoadingView al cambiar filtros
        isLoading      = true
        errorMessage   = nil
        nextCursor     = nil
        nextPage       = nil
        hasMore        = true

        do {
            let page   = try await service.list(filters: filters)
            properties = page.data
            nextCursor = page.nextCursor
            nextPage   = page.nextPage
            hasMore    = page.hasMore
        } catch {
            errorMessage = message(from: error)
        }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoading, !isLoadingMore else { return }
        guard nextCursor != nil || nextPage != nil else { return }
        isLoadingMore = true

        do {
            let page = try await service.list(
                filters: currentFilters,
                cursor:  nextCursor,
                page:    nextPage
            )
            properties.append(contentsOf: page.data)
            nextCursor = page.nextCursor
            nextPage   = page.nextPage
            hasMore    = page.hasMore
        } catch {
            // Silent — pull-to-refresh recovers
        }
        isLoadingMore = false
    }

    func refresh() async {
        await loadInitial(filters: currentFilters)
    }

    // MARK: - Helpers

    private func message(from error: Error) -> String {
        (error as? APIError)?.localizedDescription ?? error.localizedDescription
    }
}
