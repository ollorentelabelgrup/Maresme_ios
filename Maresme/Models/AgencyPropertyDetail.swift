import Foundation

struct AgencyPropertyDetail: Decodable, Identifiable {
    // Identidad
    let id:            String   // ulid
    let slug:          String
    let title:         String
    let referenceCode: String?

    // Descripción
    let description: String?
    let type:        String

    // Estado
    let status:   String
    let isActive: Bool

    // Precio
    let priceSale: Int?
    let priceRent: Int?
    let price:     Int?
    let priceType: String?

    // Superficie y características
    let surfaceM2: Int?
    let rooms:     Int?
    let bathrooms: Int?

    // Ubicación
    let municipality: String?
    let zoneId:       Int?
    let address:      String?
    let lat:          Double?
    let lng:          Double?

    // Media
    let heroImage: String?
    let photos:    [AgencyPropertyPhoto]

    // Métricas
    let leadsCount:  Int
    let healthScore: Int?

    // Timestamps
    let createdAt: Date?
    let updatedAt: Date?

    // MARK: - Computed

    var statusDisplay: AgencyProperty.StatusDisplay {
        switch status {
        case "active":   return .init(label: "Activa",    colorName: "success")
        case "draft":    return .init(label: "Borrador",  colorName: "subtext")
        case "reserved": return .init(label: "Reservada", colorName: "warning")
        case "sold":     return .init(label: "Vendida",   colorName: "purple")
        default:         return .init(label: status,      colorName: "subtext")
        }
    }

    var priceFormatted: String? {
        guard let price else { return nil }
        let suffix = priceType == "rent" ? "/mes" : ""
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: price)) ?? "\(price)"
        return "\(formatted) €\(suffix)"
    }

    var typeLabel: String {
        switch type {
        case "piso":       return "Piso"
        case "casa":       return "Casa"
        case "local":      return "Local"
        case "oficina":    return "Oficina"
        case "garaje":     return "Garaje"
        case "terreno":    return "Terreno"
        case "nave":       return "Nave industrial"
        default:           return type.capitalized
        }
    }

    // Acciones válidas según estado actual (preparado para MB-PRO-2)
    var availableActions: [PropertyAction] {
        switch status {
        case "draft":    return [.publish]
        case "active":   return [.unpublish, .reserve]
        case "reserved": return [.reactivate, .sell]
        default:         return []
        }
    }

    enum PropertyAction: String {
        case publish    = "Publicar"
        case unpublish  = "Despublicar"
        case reserve    = "Reservar"
        case reactivate = "Reactivar"
        case sell       = "Marcar como vendida"

        var icon: String {
            switch self {
            case .publish:    return "checkmark.circle"
            case .unpublish:  return "xmark.circle"
            case .reserve:    return "calendar.badge.clock"
            case .reactivate: return "arrow.uturn.left.circle"
            case .sell:       return "star.circle"
            }
        }
    }
}
