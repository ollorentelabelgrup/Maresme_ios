import SwiftUI

// MARK: - Deep link types

enum PushDeepLink: Equatable {
    case property(slug: String)
    case recommendation(slug: String)
    case alert(id: Int)
    case notification(id: Int)

    static func from(actionType: String?, target: String?) -> PushDeepLink? {
        guard let type = actionType, let target = target, !target.isEmpty else { return nil }
        switch type {
        case "property", "price_drop":
            return .property(slug: target)
        case "recommendation":
            return .recommendation(slug: target)
        case "alert_match", "alert_activated", "alert_paused":
            guard let id = Int(target) else { return nil }
            return .alert(id: id)
        case "system":
            guard let id = Int(target) else { return nil }
            return .notification(id: id)
        default:
            return nil
        }
    }
}

// MARK: - Navigation coordinator

/// Fuente de verdad para la navegación global, incluyendo deep links de push notifications.
/// Inyectado via .environment() desde MaresmeApp.
@Observable
final class NavigationCoordinator {
    var selectedTab: Int = 0

    // Señales de navegación: cada tab view observa la suya y la consume
    var pendingPropertySlug:   String? = nil
    var pendingAlertId:        Int?    = nil
    var pendingNotificationId: Int?    = nil

    func navigate(to deepLink: PushDeepLink) {
        switch deepLink {
        case .property(let slug), .recommendation(let slug):
            pendingPropertySlug = slug
            selectedTab = 0

        case .alert(let id):
            pendingAlertId = id
            selectedTab = 3

        case .notification(let id):
            pendingNotificationId = id
            selectedTab = 4
        }
    }
}
