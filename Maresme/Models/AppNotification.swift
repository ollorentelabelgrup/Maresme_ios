import Foundation

// Named AppNotification to avoid conflict with Swift's Notification
struct AppNotification: Decodable, Identifiable {
    let id:        Int
    let type:      String
    let icon:      String?
    let title:     String
    let message:   String
    let metadata:  NotificationMetadata?
    let isRead:    Bool
    let readAt:    Date?
    let createdAt: Date?
    // No CodingKeys — convertFromSnakeCase handles is_read→isRead, read_at→readAt,
    // created_at→createdAt. See CLAUDE.md §3.

    struct NotificationMetadata: Decodable {
        let actionType:   String?
        let actionTarget: String?
        let propertySlug: String?
        // No CodingKeys — convertFromSnakeCase handles action_type→actionType, etc.
    }

    var sfSymbol: String {
        switch icon {
        case "sparkles":      return "sparkles"
        case "bell":          return "bell.badge"
        case "trending_down": return "arrow.down.right"
        default:              return "info.circle"
        }
    }

    var typeLabel: String {
        switch type {
        case "recommendation":  return "Recomendación"
        case "alert_match":     return "Coincidencia"
        case "alert_activated": return "Alerta activada"
        case "alert_paused":    return "Alerta pausada"
        case "price_drop":      return "Bajada de precio"
        default:                return "Actividad"
        }
    }
}
