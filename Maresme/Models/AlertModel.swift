import Foundation

// Named AlertModel to avoid conflict with SwiftUI.Alert
// Maps AlertResource from backend:
// { id, name, status, frequency, filters, matches_count,
//   preview_matches_count, has_new_matches, created_at, last_match_at }
struct AlertModel: Decodable, Identifiable {
    let id:                  Int
    let name:                String
    let status:              String        // "active" | "paused"
    let frequency:           String        // "instant" | "daily" | "weekly"
    let filters:             AlertFilters
    let matchesCount:        Int
    let previewMatchesCount: Int
    let hasNewMatches:       Bool
    let createdAt:           Date?
    let lastMatchAt:         Date?

    var isActive: Bool { status == "active" }
    // No CodingKeys — convertFromSnakeCase handles all snake_case→camelCase
}
