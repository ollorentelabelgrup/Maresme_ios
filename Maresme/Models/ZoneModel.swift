import Foundation

struct ZoneModel: Decodable, Identifiable {
    let id:                    Int
    let slug:                  String
    let name:                  String
    let type:                  String
    let tagline:               String?
    let photoUrl:              String?
    let hasBeach:              Bool
    let hasMountain:           Bool
    let distanceBarcelonaKm:   Double?
    let population:            Int?
    let averagePrice:          Int?
    let averagePriceM2:        Int?
    let propertiesCount:       Int
    let isFeatured:            Bool

    enum CodingKeys: String, CodingKey {
        case id, slug, name, type, tagline, population
        case photoUrl            = "photo_url"
        case hasBeach            = "has_beach"
        case hasMountain         = "has_mountain"
        case distanceBarcelonaKm = "distance_barcelona_km"
        case averagePrice        = "average_price"
        case averagePriceM2      = "average_price_m2"
        case propertiesCount     = "properties_count"
        case isFeatured          = "is_featured"
    }
}
