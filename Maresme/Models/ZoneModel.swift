import Foundation

// Sin CodingKeys explícitos: el decoder usa keyDecodingStrategy = .convertFromSnakeCase
// para mapear "photo_url" → photoUrl, "has_beach" → hasBeach, etc.
// CodingKeys con raw values snake_case ROMPEN convertFromSnakeCase (gotcha documentado
// en CLAUDE.md §3): el decoder convierte el JSON key a camelCase y luego compara con el
// raw value — "photo_url" convertido es "photoUrl" ≠ raw value "photo_url" → keyNotFound.
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
}
