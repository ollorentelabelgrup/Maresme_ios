import Foundation

// Named AppNotification to avoid conflict with Swift's Notification
struct AppNotification: Decodable, Identifiable {
    let id:        Int
    let type:      String
    let title:     String
    let body:      String
    let icon:      String?
    let isRead:    Bool
    let metadata:  NotificationMetadata?
    let createdAt: Date?

    struct NotificationMetadata: Decodable {
        let actionType:   String?
        let actionTarget: String?
        let propertySlug: String?

        enum CodingKeys: String, CodingKey {
            case actionType   = "action_type"
            case actionTarget = "action_target"
            case propertySlug = "property_slug"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, type, title, body, icon, metadata
        case isRead    = "is_read"
        case createdAt = "created_at"
    }

    var sfSymbol: String {
        switch icon {
        case "sparkles":      return "sparkles"
        case "bell":          return "bell.badge"
        case "trending_down": return "arrow.down.right"
        default:              return "info.circle"
        }
    }
}
