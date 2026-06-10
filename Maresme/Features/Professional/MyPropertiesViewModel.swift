import Foundation
import Observation

@Observable
final class MyPropertiesViewModel {
    var properties:   [AgencyProperty] = []
    var isLoading:    Bool              = true
    var isLoadingMore: Bool             = false
    var errorMessage: String?           = nil
    var selectedStatus: String?         = nil  // nil = todos

    private var nextCursor: String? = nil
    private var hasMore:    Bool    = true
    private let service             = AgencyPropertyService()

    func load() async {
        guard isLoading else { return }
        errorMessage = nil
        nextCursor   = nil
        hasMore      = true

        do {
            let page    = try await service.list(status: selectedStatus)
            properties  = page.data
            nextCursor  = page.nextCursor
            hasMore     = page.nextCursor != nil
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore, let cursor = nextCursor else { return }
        isLoadingMore = true
        do {
            let page   = try await service.list(status: selectedStatus, cursor: cursor)
            properties.append(contentsOf: page.data)
            nextCursor = page.nextCursor
            hasMore    = page.nextCursor != nil
        } catch { }
        isLoadingMore = false
    }

    func reload() async {
        isLoading    = true
        errorMessage = nil
        await load()
    }

    func applyFilter(_ status: String?) async {
        guard selectedStatus != status else { return }
        selectedStatus = status
        isLoading      = true
        await load()
    }

    func isLastItem(_ property: AgencyProperty) -> Bool {
        properties.last?.id == property.id
    }
}
