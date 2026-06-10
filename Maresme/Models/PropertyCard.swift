import Foundation

struct PropertyCard: Decodable, Identifiable {
    let slug:          String
    let title:         String
    let price:         Int?
    let priceFormatted: String?
    let propertyType:  String
    let mainImage:     String?
    let rooms:         Int?
    let bathrooms:     Int?
    let surfaceM2:     Int?
    let municipality:  MunicipalityRef?
    let status:        String
    let isFeatured:    Bool
    let isNewBuild:    Bool
    let isFavorite:    Bool
    let createdAt:     Date?

    var id: String { slug }

    struct MunicipalityRef: Decodable {
        let slug: String
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case slug, title, price, rooms, bathrooms, status, municipality
        case priceFormatted = "price_formatted"
        case propertyType   = "property_type"
        case mainImage      = "main_image"
        case surfaceM2      = "surface_m2"
        case isFeatured     = "is_featured"
        case isNewBuild     = "is_new_build"
        case isFavorite     = "is_favorite"
        case createdAt      = "created_at"
    }
}
