import Foundation

struct PropertyDetail: Decodable, Identifiable {
    // -- Card fields (same as PropertyCard) --
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

    // -- Detail fields --
    let description:       String?
    let photos:            [String]
    let address:           String?
    let postalCode:        String?
    let lat:               Double?
    let lng:               Double?
    let usefulSurfaceM2:   Int?
    let floorNumber:       Int?
    let yearBuilt:         Int?
    let referenceCode:     String?
    let orientation:       String?
    let energyCertificate: String?
    let heating:           String?
    let features:          [String]
    let hasPool:           Bool
    let hasGarden:         Bool
    let hasParking:        Bool
    let hasSeaView:        Bool
    let hasElevator:       Bool
    let hasTerrace:        Bool
    let hasStorageRoom:    Bool
    let isExclusive:       Bool

    // -- Relations --
    let agency:       AgencyRef?
    let zone:         ZoneRef?

    // -- iOS-specific --
    let heroImage:    String?
    let galleryCount: Int
    let shareUrl:     String?
    let favoriteCount: Int

    var id: String { slug }

    struct MunicipalityRef: Decodable {
        let slug: String
        let name: String
    }

    struct AgencyRef: Decodable {
        let slug:    String
        let name:    String
        let phone:   String?
        let logoUrl: String?
    }

    struct ZoneRef: Decodable {
        let slug: String
        let name: String
        let type: String
    }
    // No CodingKeys — convertFromSnakeCase handles all snake_case→camelCase mapping.
}
