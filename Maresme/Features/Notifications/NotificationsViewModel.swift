import Foundation

@Observable
final class NotificationsViewModel {
    var notifications: [AppNotification] = []
    var isLoading:     Bool              = false
    var isLoadingMore: Bool              = false
    var errorMessage:  String?           = nil
    var isLoaded:      Bool              = false
    private var hasMore:    Bool         = true
    private var nextCursor: String?      = nil

    private let service: NotificationService
    private let store:   NotificationStore

    init(service: NotificationService = NotificationService(),
         store:   NotificationStore) {
        self.service = service
        self.store   = store
    }

    // MARK: - Load

    func loadIfNeeded() async {
        guard !isLoaded, !isLoading else { return }
        await load()
    }

    func load() async {
        guard !isLoading else { return }
        isLoading    = true
        errorMessage = nil
        nextCursor   = nil
        defer { isLoading = false }
        do {
            let page      = try await service.list()
            notifications = page.data
            nextCursor    = page.nextCursor
            hasMore       = page.nextCursor != nil
            isLoaded      = true
        } catch is CancellationError {
            // Task cancelled (tab hidden) — no error to show
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore, !isLoading, let cursor = nextCursor else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page       = try await service.list(cursor: cursor)
            notifications += page.data
            nextCursor     = page.nextCursor
            hasMore        = page.nextCursor != nil
        } catch {
            // Silent — pull-to-refresh recovers
        }
    }

    func refresh() async {
        isLoaded = false
        await load()
        await store.loadCount()
    }

    // MARK: - Mark read (optimistic)

    func markRead(id: Int) async {
        guard let idx = notifications.firstIndex(where: { $0.id == id }),
              !notifications[idx].isRead else { return }

        notifications[idx] = markedRead(notifications[idx])
        store.decrementUnread()
        store.removeFromRecent(id: id)

        do {
            try await service.markRead(id: id)
        } catch {
            await load()
            await store.loadCount()
        }
    }

    func markAllRead() async {
        guard notifications.contains(where: { !$0.isRead }) else { return }

        notifications = notifications.map { markedRead($0) }
        store.markAllReadLocal()

        do {
            try await service.markAllRead()
        } catch {
            await load()
            await store.loadCount()
        }
    }

    // MARK: - Delete (optimistic)

    func delete(id: Int) async {
        let wasUnread = notifications.first(where: { $0.id == id }).map { !$0.isRead } ?? false

        notifications.removeAll { $0.id == id }
        store.decrementTotal()
        if wasUnread {
            store.decrementUnread()
            store.removeFromRecent(id: id)
        }

        do {
            try await service.delete(id: id)
        } catch {
            await load()
            await store.loadCount()
        }
    }

    // MARK: - Helpers

    private func markedRead(_ n: AppNotification) -> AppNotification {
        AppNotification(
            id:        n.id,
            type:      n.type,
            icon:      n.icon,
            title:     n.title,
            message:   n.message,
            metadata:  n.metadata,
            isRead:    true,
            readAt:    n.readAt ?? Date(),
            createdAt: n.createdAt
        )
    }
}
