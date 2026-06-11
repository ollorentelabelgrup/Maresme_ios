import Foundation

@Observable
final class AlertStore {
    var alerts:   [AlertModel] = []
    var isLoaded: Bool         = false

    // Badge: alerts that currently have matches
    var newMatchesCount: Int {
        alerts.filter(\.hasNewMatches).count
    }

    var activeCount: Int {
        alerts.filter(\.isActive).count
    }

    private let service: AlertService

    init(service: AlertService = AlertService()) {
        self.service = service
    }

    // MARK: - Load

    func load() async {
        do {
            alerts   = try await service.list()
            isLoaded = true
        } catch {
            // Non-critical on initial load — empty list is safe
        }
    }

    func reload() async {
        isLoaded = false
        await load()
    }

    // MARK: - Mutations

    func create(request: CreateAlertRequest) async throws -> AlertModel {
        let alert = try await service.create(request: request)
        alerts.insert(alert, at: 0)
        return alert
    }

    func update(id: Int, request: UpdateAlertRequest) async throws -> AlertModel {
        let updated = try await service.update(id: id, request: request)
        replace(updated)
        return updated
    }

    func delete(id: Int) async throws {
        try await service.delete(id: id)
        remove(id: id)
    }

    func pause(id: Int) async throws -> AlertModel {
        let updated = try await service.pause(id: id)
        replace(updated)
        return updated
    }

    func resume(id: Int) async throws -> AlertModel {
        let updated = try await service.resume(id: id)
        replace(updated)
        return updated
    }

    // MARK: - Clear on logout

    func reset() {
        alerts   = []
        isLoaded = false
    }

    // MARK: - Helpers

    private func replace(_ alert: AlertModel) {
        if let idx = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[idx] = alert
        }
    }

    private func remove(id: Int) {
        alerts.removeAll { $0.id == id }
    }
}
