import Foundation

struct Recommendation: Decodable, Identifiable {
    let id:       Int
    let property: PropertyCard
    let score:    Int
    let quality:  String
    let isNew:    Bool
    let breakdown: RecommendationBreakdown?

    struct RecommendationBreakdown: Decodable {
        let priceScore:    Int?
        let zoneScore:     Int?
        let typeScore:     Int?
        let surfaceScore:  Int?

        enum CodingKeys: String, CodingKey {
            case priceScore   = "price_score"
            case zoneScore    = "zone_score"
            case typeScore    = "type_score"
            case surfaceScore = "surface_score"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, property, score, quality, breakdown
        case isNew = "is_new"
    }
}
