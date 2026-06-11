import Foundation

@Observable
final class NotificationStore {
    var unreadCount:  Int               = 0
    var totalCount:   Int               = 0
    var recentUnread: [AppNotification] = []   // up to 3 unread — for HomeView widget
    var isLoaded:     Bool              = false

    private let service: NotificationService

    init(service: NotificationService = NotificationService()) {
        self.service = service
    }

    // MARK: - Load (called after login / on resolveSession)

    func loadCount() async {
        do {
            let response = try await service.count()
            totalCount   = response.total
            unreadCount  = response.unread
            isLoaded     = true
            if unreadCount > 0 {
                await loadRecent()
            }
        } catch {
            // Non-critical — badges show 0 until next successful call
        }
    }

    private func loadRecent() async {
        do {
            let page     = try await service.list()
            recentUnread = Array(page.data.filter { !$0.isRead }.prefix(3))
        } catch {
            // Non-critical
        }
    }

    // MARK: - Local mutations (called by NotificationsViewModel after API calls)

    func decrementUnread() {
        unreadCount = max(0, unreadCount - 1)
    }

    func markAllReadLocal() {
        unreadCount  = 0
        recentUnread = []
    }

    func decrementTotal() {
        totalCount = max(0, totalCount - 1)
    }

    func removeFromRecent(id: Int) {
        recentUnread.removeAll { $0.id == id }
    }

    // MARK: - Reset on logout

    func reset() {
        unreadCount  = 0
        totalCount   = 0
        recentUnread = []
        isLoaded     = false
    }
}
