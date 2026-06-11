import Foundation

// MARK: - PropertySearchFilters
// Todos los filtros soportados por GET /api/v1/properties.
// Equatable + Hashable para NavigationLink(value:) y .onChange(of:).

struct PropertySearchFilters: Equatable, Hashable {
    var zone:       String? = nil   // slug de municipio
    var type:       String? = nil   // tipo de propiedad
    var priceMin:   Int?    = nil
    var priceMax:   Int?    = nil
    var rooms:      Int?    = nil   // mínimo de habitaciones
    var bathrooms:  Int?    = nil   // mínimo de baños
    var surfaceMin: Int?    = nil   // m² mínimo
    var surfaceMax: Int?    = nil   // m² máximo
    var sort:       String  = "featured"

    // MARK: - Estado

    var isEmpty: Bool {
        zone == nil && type == nil && priceMin == nil && priceMax == nil
        && rooms == nil && bathrooms == nil && surfaceMin == nil && surfaceMax == nil
        && sort == "featured"
    }

    var activeFilterCount: Int {
        var n = 0
        if zone      != nil      { n += 1 }
        if type      != nil      { n += 1 }
        if priceMin  != nil      { n += 1 }
        if priceMax  != nil      { n += 1 }
        if rooms     != nil      { n += 1 }
        if bathrooms != nil      { n += 1 }
        if surfaceMin != nil     { n += 1 }
        if surfaceMax != nil     { n += 1 }
        if sort != "featured"    { n += 1 }
        return n
    }

    // MARK: - Chips activos (para la barra de filtros activos)

    struct Chip: Identifiable, Equatable {
        let id:    String
        let label: String
    }

    var activeChips: [Chip] {
        var chips: [Chip] = []
        if let z = zone {
            let name = Municipality.all.first(where: { $0.slug == z })?.name ?? z
            chips.append(.init(id: "zone", label: name))
        }
        if let t = type {
            let name = PropertyType.all.first(where: { $0.value == t })?.label ?? t.capitalized
            chips.append(.init(id: "type", label: name))
        }
        if let pMin = priceMin {
            chips.append(.init(id: "priceMin", label: "Desde \(pMin.priceLabel)"))
        }
        if let pMax = priceMax {
            chips.append(.init(id: "priceMax", label: "Hasta \(pMax.priceLabel)"))
        }
        if let r = rooms {
            chips.append(.init(id: "rooms", label: "≥ \(r) hab."))
        }
        if let b = bathrooms {
            chips.append(.init(id: "bathrooms", label: "≥ \(b) baños"))
        }
        if let sMin = surfaceMin {
            chips.append(.init(id: "surfaceMin", label: "Desde \(sMin) m²"))
        }
        if let sMax = surfaceMax {
            chips.append(.init(id: "surfaceMax", label: "Hasta \(sMax) m²"))
        }
        if sort != "featured" {
            let label = SortOption.all.first(where: { $0.value == sort })?.shortLabel ?? sort
            chips.append(.init(id: "sort", label: label))
        }
        return chips
    }

    mutating func remove(chipId: String) {
        switch chipId {
        case "zone":       zone       = nil
        case "type":       type       = nil
        case "priceMin":   priceMin   = nil
        case "priceMax":   priceMax   = nil
        case "rooms":      rooms      = nil
        case "bathrooms":  bathrooms  = nil
        case "surfaceMin": surfaceMin = nil
        case "surfaceMax": surfaceMax = nil
        case "sort":       sort       = "featured"
        default:           break
        }
    }

    // MARK: - Título navegación (para destinos de quick search)

    var navigationTitle: String {
        var parts: [String] = []
        if let t = type {
            parts.append(PropertyType.all.first(where: { $0.value == t })?.label ?? t.capitalized)
        }
        if let z = zone {
            let name = Municipality.all.first(where: { $0.slug == z })?.name ?? z.capitalized
            if parts.isEmpty { parts.append(name) }
            else             { parts.append("en \(name)") }
        }
        if !parts.isEmpty { return parts.joined(separator: " ") }
        if sort == "newest" { return "Más recientes" }
        if sort == "price_asc"  { return "Por precio ↑" }
        if sort == "price_desc" { return "Por precio ↓" }
        return "Propiedades"
    }

    // MARK: - Query string

    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let z = zone       { items.append(.init(name: "zone",        value: z)) }
        if let t = type       { items.append(.init(name: "type",        value: t)) }
        if let v = priceMin   { items.append(.init(name: "price_min",   value: "\(v)")) }
        if let v = priceMax   { items.append(.init(name: "price_max",   value: "\(v)")) }
        if let v = rooms      { items.append(.init(name: "rooms",       value: "\(v)")) }
        if let v = bathrooms  { items.append(.init(name: "bathrooms",   value: "\(v)")) }
        if let v = surfaceMin { items.append(.init(name: "surface_min", value: "\(v)")) }
        if let v = surfaceMax { items.append(.init(name: "surface_max", value: "\(v)")) }
        if sort != "featured" { items.append(.init(name: "sort",        value: sort)) }
        return items
    }
}

// MARK: - Reference data

extension PropertySearchFilters {

    struct Municipality: Identifiable {
        var id: String { slug }
        let slug: String
        let name: String

        static let all: [Municipality] = [
            .init(slug: "mataro",                    name: "Mataró"),
            .init(slug: "el-masnou",                 name: "El Masnou"),
            .init(slug: "alella",                    name: "Alella"),
            .init(slug: "arenys-de-mar",             name: "Arenys de Mar"),
            .init(slug: "arenys-de-munt",            name: "Arenys de Munt"),
            .init(slug: "argentona",                 name: "Argentona"),
            .init(slug: "cabrils",                   name: "Cabrils"),
            .init(slug: "canet-de-mar",              name: "Canet de Mar"),
            .init(slug: "caldes-destrac",            name: "Caldes d'Estrac"),
            .init(slug: "calella",                   name: "Calella"),
            .init(slug: "dosrius",                   name: "Dosrius"),
            .init(slug: "malgrat-de-mar",            name: "Malgrat de Mar"),
            .init(slug: "montgat",                   name: "Montgat"),
            .init(slug: "pineda-de-mar",             name: "Pineda de Mar"),
            .init(slug: "premia-de-dalt",            name: "Premià de Dalt"),
            .init(slug: "premia-de-mar",             name: "Premià de Mar"),
            .init(slug: "sant-andreu-de-llavaneres", name: "Sant Andreu de Llavaneres"),
            .init(slug: "sant-pol-de-mar",           name: "Sant Pol de Mar"),
            .init(slug: "sant-vicenc-de-montalt",    name: "Sant Vicenç de Montalt"),
            .init(slug: "santa-susanna",             name: "Santa Susanna"),
            .init(slug: "teia",                      name: "Teià"),
            .init(slug: "tiana",                     name: "Tiana"),
            .init(slug: "tordera",                   name: "Tordera"),
            .init(slug: "vilassar-de-dalt",          name: "Vilassar de Dalt"),
            .init(slug: "vilassar-de-mar",           name: "Vilassar de Mar"),
        ]
    }

    struct PropertyType: Identifiable {
        var id: String { value }
        let value: String
        let label: String
        let icon:  String

        static let all: [PropertyType] = [
            .init(value: "piso",    label: "Piso",    icon: "building.2"),
            .init(value: "casa",    label: "Casa",    icon: "house"),
            .init(value: "atico",   label: "Ático",   icon: "building"),
            .init(value: "duplex",  label: "Dúplex",  icon: "house.and.flag"),
            .init(value: "terreno", label: "Terreno", icon: "leaf"),
            .init(value: "local",   label: "Local",   icon: "storefront"),
            .init(value: "oficina", label: "Oficina", icon: "briefcase"),
        ]
    }

    struct SortOption: Identifiable {
        var id: String { value }
        let value:      String
        let label:      String
        let shortLabel: String

        static let all: [SortOption] = [
            .init(value: "featured",   label: "Destacados",     shortLabel: "Destacados"),
            .init(value: "newest",     label: "Más recientes",  shortLabel: "Recientes"),
            .init(value: "price_asc",  label: "Precio: menor a mayor", shortLabel: "Precio ↑"),
            .init(value: "price_desc", label: "Precio: mayor a menor", shortLabel: "Precio ↓"),
        ]
    }
}

// MARK: - Helpers

private extension Int {
    var priceLabel: String {
        let f = NumberFormatter()
        f.numberStyle        = .decimal
        f.groupingSeparator  = "."
        f.decimalSeparator   = ","
        return "\(f.string(from: NSNumber(value: self)) ?? "\(self)") €"
    }
}
