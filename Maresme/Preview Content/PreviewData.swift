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

    static let propertyDetail = PropertyDetail(
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
        createdAt:      Date(),
        description:    "Fantástico piso luminoso en el corazón de Alella, con vistas al mar y a la montaña. Reformado en 2022, con cocina equipada y suelos de parquet.",
        photos:         [],
        address:        "Carrer Major, 12",
        postalCode:     "08328",
        lat:            nil,
        lng:            nil,
        usefulSurfaceM2: 88,
        floorNumber:    3,
        yearBuilt:      1985,
        referenceCode:  "ALE-0042",
        orientation:    "Sur",
        energyCertificate: "C",
        heating:        "Gas natural",
        features:       ["Armarios empotrados", "Doble acristalamiento"],
        hasPool:        false,
        hasGarden:      false,
        hasParking:     true,
        hasSeaView:     true,
        hasElevator:    true,
        hasTerrace:     true,
        hasStorageRoom: true,
        isExclusive:    false,
        agency:         .init(slug: "inmobiliaria-maresme", name: "Inmobiliaria Maresme", phone: "+34 937 000 000", logoUrl: nil),
        zone:           .init(slug: "alella", name: "Alella", type: "municipality"),
        heroImage:      nil,
        galleryCount:   0,
        shareUrl:       "https://maresme.es/propiedades/piso-alella-3hab-luminoso",
        favoriteCount:  5
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
        status:              "active",
        frequency:           "daily",
        filters:             AlertFilters(zone: "alella", type: "piso", priceMax: 350000, rooms: 2),
        matchesCount:        48,
        previewMatchesCount: 12,
        hasNewMatches:       true,
        createdAt:           Date(),
        lastMatchAt:         Date()
    )

    static let alertModelPaused = AlertModel(
        id:                  2,
        name:                "Casas con jardín",
        status:              "paused",
        frequency:           "weekly",
        filters:             AlertFilters(type: "casa", priceMax: 500000, rooms: 3),
        matchesCount:        5,
        previewMatchesCount: 0,
        hasNewMatches:       false,
        createdAt:           Date(),
        lastMatchAt:         nil
    )

    static let recommendation = Recommendation(
        score:    87,
        quality:  "very_high",
        reason:   "El municipio y el presupuesto coinciden con tus preferencias.",
        isNew:    true,
        viewedAt: nil,
        property: PreviewData.propertyCard
    )

    static let recommendationDetail = RecommendationDetail(
        matching: .init(
            score:   87,
            quality: "very_high",
            reason:  "El municipio y el presupuesto coinciden con tus preferencias.",
            breakdown: .init(municipality: 95, budget: 82, propertyType: 90, affinity: 78)
        ),
        property: PreviewData.propertyDetail
    )

    static let notification = AppNotification(
        id:        1,
        type:      "recommendation",
        icon:      "sparkles",
        title:     "Nueva recomendación",
        message:   "Piso en Alella — 87 puntos de coincidencia",
        metadata:  .init(
            actionType:   "property",
            actionTarget: "piso-alella-3hab-luminoso",
            propertySlug: "piso-alella-3hab-luminoso"
        ),
        isRead:    false,
        readAt:    nil,
        createdAt: Date()
    )

    static let notificationList: [AppNotification] = [
        notification,
        AppNotification(
            id:        2,
            type:      "alert_match",
            icon:      "bell",
            title:     "Nueva coincidencia en tu alerta",
            message:   "Aparecieron 3 nuevas propiedades para 'Pisos en Alella'",
            metadata:  .init(actionType: "alert_match", actionTarget: "1", propertySlug: nil),
            isRead:    true,
            readAt:    Date(),
            createdAt: Date()
        ),
        AppNotification(
            id:        3,
            type:      "price_drop",
            icon:      "trending_down",
            title:     "Bajada de precio",
            message:   "El piso en Mataró ha reducido su precio un 5%",
            metadata:  .init(actionType: "property", actionTarget: "piso-mataro-2hab", propertySlug: "piso-mataro-2hab"),
            isRead:    false,
            readAt:    nil,
            createdAt: Date()
        )
    ]
}
