import Foundation
import Observation

@Observable
final class AgencyPropertyEditViewModel {

    // MARK: - Mode

    enum Mode {
        case create
        case edit(slug: String)
    }

    // MARK: - Form fields

    var title:        String = ""
    var description:  String = ""
    var type:         String = "piso"
    var address:      String = ""
    var priceSaleStr: String = ""
    var priceRentStr: String = ""
    var roomsStr:     String = ""
    var bathroomsStr: String = ""
    var surfaceStr:   String = ""
    var usefulStr:    String = ""
    var floorStr:     String = ""
    var latStr:       String = ""
    var lngStr:       String = ""
    var selectedZoneId: Int? = nil

    // Extras
    var hasElevator:    Bool = false
    var hasTerrace:     Bool = false
    var hasParking:     Bool = false
    var hasPool:        Bool = false
    var hasStorageRoom: Bool = false
    var hasGarden:      Bool = false
    var hasSeaView:     Bool = false

    // Clasificación
    var isNewBuild:  Bool = false
    var isExclusive: Bool = false
    var isFeatured:  Bool = false

    // MARK: - UI state

    var isSaving:     Bool    = false
    var saveError:    String? = nil
    var zones:        [ZoneModel] = []
    var isLoadingZones: Bool = false

    // MARK: - Private

    private let mode:         Mode
    private let writeService: AgencyPropertyWriteService

    // MARK: - Init (edit)

    init(
        property: AgencyPropertyDetail,
        writeService: AgencyPropertyWriteService = AgencyPropertyWriteService()
    ) {
        self.mode         = .edit(slug: property.slug)
        self.writeService = writeService
        populateFields(from: property)
    }

    // MARK: - Init (create)

    init(writeService: AgencyPropertyWriteService = AgencyPropertyWriteService()) {
        self.mode         = .create
        self.writeService = writeService
    }

    // MARK: - Save

    func save() async throws -> AgencyPropertyDetail {
        isSaving  = true
        saveError = nil
        defer { isSaving = false }
        let payload = buildPayload()
        do {
            switch mode {
            case .create:
                return try await writeService.create(payload: payload)
            case .edit(let slug):
                return try await writeService.update(slug: slug, payload: payload)
            }
        } catch let error as APIError {
            saveError = error.localizedDescription
            throw error
        } catch {
            saveError = error.localizedDescription
            throw error
        }
    }

    // MARK: - Load zones

    func loadZones() async {
        guard zones.isEmpty, !isLoadingZones else { return }
        isLoadingZones = true
        if let result = try? await APIClient.shared.request(
            Endpoint(.get, "/zones")
        ) as WrappedResponse<[ZoneModel]> {
            zones = result.data
        }
        isLoadingZones = false
    }

    // MARK: - Validation

    var validationError: String? {
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            return "El título es obligatorio."
        }
        let hasSalePrice = !priceSaleStr.trimmingCharacters(in: .whitespaces).isEmpty
        let hasRentPrice = !priceRentStr.trimmingCharacters(in: .whitespaces).isEmpty
        if case .create = mode, !hasSalePrice && !hasRentPrice {
            return "Indica al menos un precio de venta o alquiler."
        }
        if let price = Int(priceSaleStr), price <= 0 {
            return "El precio de venta debe ser mayor que 0."
        }
        if let surface = Int(surfaceStr), surface <= 0 {
            return "La superficie debe ser mayor que 0."
        }
        return nil
    }

    var navigationTitle: String {
        switch mode {
        case .create: return "Nueva propiedad"
        case .edit:   return "Editar propiedad"
        }
    }

    // MARK: - Private

    private func populateFields(from p: AgencyPropertyDetail) {
        title        = p.title
        description  = p.description ?? ""
        type         = p.type
        address      = p.address ?? ""
        priceSaleStr = p.priceSale.map(String.init) ?? ""
        priceRentStr = p.priceRent.map(String.init) ?? ""
        roomsStr     = p.rooms.map(String.init) ?? ""
        bathroomsStr = p.bathrooms.map(String.init) ?? ""
        surfaceStr   = p.surfaceM2.map(String.init) ?? ""
        usefulStr    = p.usefulSurfaceM2.map(String.init) ?? ""
        floorStr     = p.floorNumber.map(String.init) ?? ""
        latStr       = p.lat.map { String(format: "%.6f", $0) } ?? ""
        lngStr       = p.lng.map { String(format: "%.6f", $0) } ?? ""
        selectedZoneId = p.zoneId

        hasElevator    = p.hasElevator    ?? false
        hasTerrace     = p.hasTerrace     ?? false
        hasParking     = p.hasParking     ?? false
        hasPool        = p.hasPool        ?? false
        hasStorageRoom = p.hasStorageRoom ?? false
        hasGarden      = p.hasGarden      ?? false
        hasSeaView     = p.hasSeaView     ?? false

        isNewBuild  = p.isNewBuild  ?? false
        isExclusive = p.isExclusive ?? false
        isFeatured  = p.isFeatured  ?? false
    }

    private func buildPayload() -> UpdatePropertyPayload {
        UpdatePropertyPayload(
            title:           title.trimmingCharacters(in: .whitespaces).isEmpty ? nil : title,
            description:     description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description,
            type:            type,
            zoneId:          selectedZoneId,
            address:         address.trimmingCharacters(in: .whitespaces).isEmpty ? nil : address,
            lat:             Double(latStr),
            lng:             Double(lngStr),
            priceSale:       Int(priceSaleStr),
            priceRent:       Int(priceRentStr),
            rooms:           Int(roomsStr),
            bathrooms:       Int(bathroomsStr),
            surfaceM2:       Int(surfaceStr),
            usefulSurfaceM2: Int(usefulStr),
            floorNumber:     Int(floorStr),
            hasElevator:     hasElevator,
            hasTerrace:      hasTerrace,
            hasParking:      hasParking,
            hasPool:         hasPool,
            hasStorageRoom:  hasStorageRoom,
            hasGarden:       hasGarden,
            hasSeaView:      hasSeaView,
            isNewBuild:      isNewBuild,
            isExclusive:     isExclusive,
            isFeatured:      isFeatured
        )
    }
}
