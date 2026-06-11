import Foundation

@Observable
final class AlertsViewModel {
    var isLoading:    Bool    = false
    var errorMessage: String? = nil

    private let store: AlertStore

    init(store: AlertStore) {
        self.store = store
    }

    var alerts: [AlertModel] { store.alerts }

    func loadIfNeeded() async {
        guard !store.isLoaded else { return }
        isLoading = true
        await store.load()
        isLoading = false
    }

    func refresh() async {
        isLoading = true
        await store.reload()
        isLoading = false
    }

    func delete(id: Int) async {
        do {
            try await store.delete(id: id)
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
    }

    func toggleActive(alert: AlertModel) async {
        do {
            if alert.isActive {
                _ = try await store.pause(id: alert.id)
            } else {
                _ = try await store.resume(id: alert.id)
            }
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
    }
}
