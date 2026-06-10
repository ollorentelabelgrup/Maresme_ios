import Foundation

// Named AlertModel to avoid conflict with SwiftUI.Alert
struct AlertModel: Decodable, Identifiable {
    let id:                 Int
    let name:               String
    let zone:               String?
    let propertyType:       String?
    let priceMin:           Int?
    let priceMax:           Int?
    let roomsMin:           Int?
    let isActive:           Bool
    let previewMatchesCount: Int?
    let hasNewMatches:      Bool
    let createdAt:          Date?

    enum CodingKeys: String, CodingKey {
        case id, name, zone
        case propertyType       = "property_type"
        case priceMin           = "price_min"
        case priceMax           = "price_max"
        case roomsMin           = "rooms_min"
        case isActive           = "is_active"
        case previewMatchesCount = "preview_matches_count"
        case hasNewMatches      = "has_new_matches"
        case createdAt          = "created_at"
    }
}
