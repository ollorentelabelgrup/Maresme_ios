import Foundation

// MARK: - Shared preview data for SwiftUI #Preview macros

enum PreviewData {
    static let user = UserModel(
        id:            1,
        ulid:          "01HV1234ABCDEF",
        name:          "Joan Barceló",
        email:         "joan@example.com",
        phone:         nil,
        avatar:        nil,
        bio:           nil,
        role:          "user",
        emailVerified: true,
        createdAt:     Date()
    )

    static let professionalUser = UserModel(
        id:            2,
        ulid:          "01HV5678GHIJKL",
        name:          "Maria García",
        email:         "maria@inmobiliaria.com",
        phone:         "+34 937 000 000",
        avatar:        nil,
        bio:           "Agente inmobiliaria en el Maresme.",
        role:          "professional",
        emailVerified: true,
        createdAt:     Date()
    )

    static let agency = AgencyModel(
        id:      1,
        slug:    "inmobiliaria-maresme",
        name:    "Inmobiliaria Maresme",
        logoUrl: nil,
        phone:   "+34 937 000 000",
        email:   "info@inmobiliaria-maresme.com",
        website: "https://inmobiliaria-maresme.com",
        address: "Carrer Major, 10, Mataró",
        myRole:  "admin"
    )

    static let propertyCard = PropertyCard(
        slug:           "piso-alella-3hab-luminoso",
        title:          "Piso luminoso con vistas al mar",
        price:          285000,
        priceFormatted: "285.000 €",
        propertyType:   "piso",
        mainImage:      nil,
        rooms:          3,
        bathrooms:      2,
        surfaceM2:      95,
        municipality:   .init(slug: "alella", name: "Alella"),
        status:         "active",
        isFeatured:     true,
        isNewBuild:     false,
        isFavorite:     false,
        createdAt:      Date()
    )

    static let zone = ZoneModel(
        id:                    1,
        slug:                  "alella",
        name:                  "Alella",
        type:                  "municipality",
        tagline:               "El encanto mediterráneo del Maresme",
        photoUrl:              nil,
        hasBeach:              true,
        hasMountain:           true,
        distanceBarcelonaKm:   23.0,
        population:            9200,
        averagePrice:          320000,
        averagePriceM2:        2800,
        propertiesCount:       48,
        isFeatured:            true
    )

    static let alertModel = AlertModel(
        id:                  1,
        name:                "Pisos en Alella",
        zone:                "alella",
        propertyType:        "piso",
        priceMin:            150000,
        priceMax:            350000,
        roomsMin:            2,
        isActive:            true,
        previewMatchesCount: 12,
        hasNewMatches:       true,
        createdAt:           Date()
    )

    static let recommendation = Recommendation(
        id:        1,
        property:  PreviewData.propertyCard,
        score:     87,
        quality:   "high",
        isNew:     true,
        breakdown: .init(priceScore: 90, zoneScore: 85, typeScore: 88, surfaceScore: 84)
    )

    static let notification = AppNotification(
        id:        1,
        type:      "recommendation",
        title:     "Nueva recomendación",
        body:      "Piso en Alella — 87 puntos de coincidencia",
        icon:      "sparkles",
        isRead:    false,
        metadata:  .init(
            actionType:   "property",
            actionTarget: "piso-alella-3hab-luminoso",
            propertySlug: "piso-alella-3hab-luminoso"
        ),
        createdAt: Date()
    )
}
