import Foundation

@Observable
final class AlertDetailViewModel {
    // Matches pagination
    var matches:      [PropertyCard] = []
    var isLoadingMatches:   Bool     = false
    var isLoadingMoreMatches: Bool   = false
    var hasMoreMatches:     Bool     = true
    var matchesError:       String?  = nil

    // Actions
    var isActionInProgress: Bool     = false
    var actionError:        String?  = nil

    private var nextCursor: String?  = nil
    private let alertId: Int
    private let alertService: AlertService
    private let store:        AlertStore

    init(alertId: Int, alertService: AlertService = AlertService(), store: AlertStore) {
        self.alertId      = alertId
        self.alertService = alertService
        self.store        = store
    }

    // Convenience — live alert from store
    func currentAlert(fallback: AlertModel) -> AlertModel {
        store.alerts.first(where: { $0.id == alertId }) ?? fallback
    }

    // MARK: - Matches

    func loadMatches() async {
        guard !isLoadingMatches else { return }
        isLoadingMatches = true
        matchesError     = nil
        nextCursor       = nil
        hasMoreMatches   = true

        do {
            let page   = try await alertService.matches(id: alertId, cursor: nil)
            matches    = page.data
            nextCursor = page.nextCursor
            hasMoreMatches = page.nextCursor != nil
        } catch {
            matchesError = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isLoadingMatches = false
    }

    func loadMoreMatches() async {
        guard hasMoreMatches, !isLoadingMatches, !isLoadingMoreMatches,
              let cursor = nextCursor else { return }
        isLoadingMoreMatches = true

        do {
            let page = try await alertService.matches(id: alertId, cursor: cursor)
            matches.append(contentsOf: page.data)
            nextCursor     = page.nextCursor
            hasMoreMatches = page.nextCursor != nil
        } catch {
            matchesError = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isLoadingMoreMatches = false
    }

    // MARK: - Actions

    func toggleActive(current: AlertModel) async {
        isActionInProgress = true
        actionError        = nil
        do {
            if current.isActive {
                _ = try await store.pause(id: alertId)
            } else {
                _ = try await store.resume(id: alertId)
            }
        } catch {
            actionError = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isActionInProgress = false
    }

    func delete() async throws {
        isActionInProgress = true
        try await store.delete(id: alertId)
        isActionInProgress = false
    }
}
