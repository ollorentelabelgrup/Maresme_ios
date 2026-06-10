import Foundation

struct FavoriteModel: Decodable, Identifiable {
    let id:       Int
    let property: PropertyCard
    let savedAt:  Date?

    enum CodingKeys: String, CodingKey {
        case id, property
        case savedAt = "saved_at"
    }
}
