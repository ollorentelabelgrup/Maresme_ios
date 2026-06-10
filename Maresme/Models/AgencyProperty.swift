import Foundation

struct AgencyProperty: Decodable, Identifiable {
    let id:           String   // ulid
    let slug:         String
    let title:        String
    let status:       String
    let price:        Int?
    let priceType:    String?
    let municipality: String?
    let leadsCount:   Int
    let heroImage:    String?
    let createdAt:    Date?

    var statusDisplay: StatusDisplay {
        switch status {
        case "active":   return StatusDisplay(label: "Activa",     colorName: "success")
        case "draft":    return StatusDisplay(label: "Borrador",   colorName: "subtext")
        case "reserved": return StatusDisplay(label: "Reservada",  colorName: "warning")
        case "sold":     return StatusDisplay(label: "Vendida",    colorName: "purple")
        default:         return StatusDisplay(label: status,       colorName: "subtext")
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

    struct StatusDisplay {
        let label:     String
        let colorName: String
    }
}
