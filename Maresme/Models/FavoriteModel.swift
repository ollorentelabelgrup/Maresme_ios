import Foundation

// FavoriteResource → { "id": N, "created_at": "...", "property": PropertyCard }
struct FavoriteModel: Decodable, Identifiable {
    let id:        Int
    let createdAt: Date?       // JSON: created_at → convertFromSnakeCase → createdAt
    let property:  PropertyCard
    // No CodingKeys — convertFromSnakeCase handles snake_case→camelCase
}
