import Foundation

// MARK: - Lista (GET /api/v1/recommendations — cursor paginated)
// RecommendationResource envuelve UserPropertyMatch.
// Campos: score, quality, reason, is_new (viewed_at===null), viewed_at, property (PropertyCard)
struct Recommendation: Decodable, Identifiable, Hashable {
    let score:    Int
    let quality:  String    // "excellent" | "very_high" | "high" | "medium" | "low"
    let reason:   String?
    let isNew:    Bool      // true = nunca abierta por el usuario
    let viewedAt: Date?
    let property: PropertyCard

    var id: String { property.slug }

    // Hashable por slug para poder usar como valor de NavigationLink
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Recommendation, rhs: Recommendation) -> Bool { lhs.id == rhs.id }

    // No CodingKeys — convertFromSnakeCase: is_new→isNew, viewed_at→viewedAt
}

// MARK: - Detalle (GET /api/v1/recommendations/{slug})
// Estructura no estándar: { "data": { "matching": {...}, "property": PropertyDetailResource } }
struct RecommendationDetail: Decodable {
    let matching: MatchingInfo
    let property: PropertyDetail

    struct MatchingInfo: Decodable {
        let score:     Int
        let quality:   String
        let reason:    String?
        let breakdown: MatchBreakdown

        struct MatchBreakdown: Decodable {
            let municipality:  Int
            let budget:        Int
            let propertyType:  Int    // property_type → propertyType (convertFromSnakeCase)
            let affinity:      Int
            // No CodingKeys — convertFromSnakeCase maneja property_type → propertyType
        }
    }
}

// MARK: - Contadores (GET /api/v1/recommendations/count)
struct RecommendationCountResponse: Decodable {
    let count:      Int
    let unviewed:   Int
    let highScore:  Int     // high_score → highScore (convertFromSnakeCase)
    // No CodingKeys
}

// MARK: - Refresh (POST /api/v1/recommendations/refresh)
struct RecommendationRefreshResponse: Decodable {
    let generated:  Int
    let updated:    Int
    let highScore:  Int     // high_score → highScore (convertFromSnakeCase)
    // No CodingKeys
}
