import Foundation

// MARK: - Decodable (received from backend)
// No CodingKeys — convertFromSnakeCase maps price_min→priceMin, etc.
// All fields have = nil defaults so the memberwise init allows partial construction in previews.
struct AlertFilters: Decodable {
    var zone:       String? = nil
    var type:       String? = nil
    var priceMin:   Int?    = nil
    var priceMax:   Int?    = nil
    var rooms:      Int?    = nil
    var bathrooms:  Int?    = nil
    var surfaceMin: Int?    = nil
    var surfaceMax: Int?    = nil
}

// MARK: - Encodable (sent to backend)
// CodingKeys with snake_case raw values are correct here because this type
// is only used with JSONEncoder (no convertFromSnakeCase involved).
struct AlertFiltersRequest: Encodable {
    var zone:       String?
    var type:       String?
    var priceMin:   Int?
    var priceMax:   Int?
    var rooms:      Int?
    var bathrooms:  Int?
    var surfaceMin: Int?
    var surfaceMax: Int?

    enum CodingKeys: String, CodingKey {
        case zone, type, rooms, bathrooms
        case priceMin   = "price_min"
        case priceMax   = "price_max"
        case surfaceMin = "surface_min"
        case surfaceMax = "surface_max"
    }
}

// MARK: - Request bodies

struct CreateAlertRequest: Encodable {
    let name:      String
    let frequency: String
    let filters:   AlertFiltersRequest
}

struct UpdateAlertRequest: Encodable {
    var name:      String?
    var frequency: String?
    var filters:   AlertFiltersRequest?
}
