import Foundation
import Observation

@Observable
final class ActivityViewModel {
    var activities:    [AgencyActivity] = []
    var isLoading:     Bool             = true
    var isLoadingMore: Bool             = false
    var errorMessage:  String?          = nil

    private var nextCursor: String? = nil
    private var hasMore:    Bool    = true
    private let service             = AgencyActivityService()

    func load() async {
        guard isLoading else { return }
        errorMessage = nil
        nextCursor   = nil
        hasMore      = true

        do {
            let page    = try await service.feed()
            activities  = page.data
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
            let page = try await service.feed(cursor: cursor)
            activities.append(contentsOf: page.data)
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

    func isLastItem(_ activity: AgencyActivity) -> Bool {
        activities.last?.id == activity.id
    }
}
