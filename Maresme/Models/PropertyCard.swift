import Foundation

struct PropertyCard: Decodable, Identifiable {
    let slug:           String
    let title:          String
    let price:          Int?
    let priceFormatted: String?
    let propertyType:   String
    let mainImage:      String?
    let rooms:          Int?
    let bathrooms:      Int?
    let surfaceM2:      Int?
    let municipality:   MunicipalityRef?
    let status:         String
    let isFeatured:     Bool
    let isNewBuild:     Bool
    let isFavorite:     Bool
    let createdAt:      Date?

    var id: String { slug }

    struct MunicipalityRef: Decodable {
        let slug: String
        let name: String
    }
    // No CodingKeys — convertFromSnakeCase handles all snake_case→camelCase mapping.
    // See CLAUDE.md §3 for the trap with CodingKeys + convertFromSnakeCase.
}
