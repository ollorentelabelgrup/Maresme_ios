import Foundation
import Observation
import UIKit

@Observable
final class AgencyPropertyEditViewModel {

    // MARK: - Mode

    enum Mode {
        case create
        case edit(slug: String)
    }

    // MARK: - Campos del formulario

    var title:         String = ""
    var description:   String = ""
    var type:          String = "piso"
    var referenceCode: String = ""
    var address:       String = ""
    var priceSaleStr:  String = ""
    var priceRentStr:  String = ""
    var roomsStr:      String = ""
    var bathroomsStr:  String = ""
    var surfaceStr:    String = ""
    var usefulStr:     String = ""
    var floorStr:      String = ""
    var lat:           Double? = nil
    var lng:           Double? = nil
    var selectedZoneId: Int?  = nil

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

    // MARK: - Fotos (solo modo creación)

    var pendingPhotos:     [UIImage] = []
    var isUploadingPhotos: Bool      = false

    // MARK: - Estado UI

    var isSaving:         Bool              = false
    var saveError:        String?           = nil
    var showSaveAlert:    Bool              = false
    var fieldErrors:      [String: String]  = [:]
    var zones:            [ZoneModel]       = []
    var isLoadingZones:   Bool              = false
    var publishedAfterSave: Bool            = false

    // MARK: - Privado

    private let mode:         Mode
    private let writeService: AgencyPropertyWriteService

    // MARK: - Init edición

    init(
        property: AgencyPropertyDetail,
        writeService: AgencyPropertyWriteService = AgencyPropertyWriteService()
    ) {
        self.mode         = .edit(slug: property.slug)
        self.writeService = writeService
        populateFields(from: property)
    }

    // MARK: - Init creación

    init(writeService: AgencyPropertyWriteService = AgencyPropertyWriteService()) {
        self.mode         = .create
        self.writeService = writeService
    }

    // MARK: - Guardar

    func save() async throws -> AgencyPropertyDetail {
        isSaving    = true
        saveError   = nil
        fieldErrors = [:]
        defer { isSaving = false }

        let payload = buildPayload()
        do {
            switch mode {
            case .create:
                let created = try await writeService.create(payload: payload)
                await uploadPendingPhotos(slug: created.slug)
                return created
            case .edit(let slug):
                return try await writeService.update(slug: slug, payload: payload)
            }
        } catch {
            handleAPIError(error)
            throw error
        }
    }

    // MARK: - Guardar + Publicar

    // Crea la propiedad (draft) y después la publica directamente.
    // Si el paso de publicación falla, devuelve el borrador creado (sin re-throw).
    func saveAndPublish() async throws -> AgencyPropertyDetail {
        let saved = try await save()
        publishedAfterSave = false
        do {
            let published = try await writeService.publish(slug: saved.slug)
            publishedAfterSave = true
            return published
        } catch {
            // La propiedad se creó como borrador pero no se pudo publicar.
            // Devolvemos el borrador sin propagar el error de publicación.
            return saved
        }
    }

    // MARK: - Fotos

    func addPendingPhoto(_ image: UIImage) {
        pendingPhotos.append(image)
    }

    func removePendingPhoto(at index: Int) {
        guard pendingPhotos.indices.contains(index) else { return }
        pendingPhotos.remove(at: index)
    }

    private func uploadPendingPhotos(slug: String) async {
        print("[Photos] selected: \(pendingPhotos.count)")
        guard !pendingPhotos.isEmpty else { return }
        print("[Photos] uploading to property: \(slug)")
        isUploadingPhotos = true
        defer { isUploadingPhotos = false }
        do {
            let uploaded = try await writeService.uploadPhotos(slug: slug, images: pendingPhotos)
            print("[Photos] upload count: \(uploaded.count)")
            print("[Photos] response: \(uploaded.map { "id:\($0.id) url:\($0.url)" })")
            guard let firstId = uploaded.first?.id else {
                print("[Photos] ⚠️ servidor devolvió array vacío")
                return
            }
            do {
                let withPrimary = try await writeService.setPrimaryPhoto(propertySlug: slug, photoId: firstId)
                print("[Photos] set-primary OK — total: \(withPrimary.count)")
            } catch {
                print("[Photos] ⚠️ setPrimaryPhoto falló (fotos subidas, sin primaria):", error)
            }
        } catch {
            print("[Photos] ❌ uploadPhotos falló:", error)
            saveError     = "Las fotos no se pudieron subir: \((error as? APIError)?.localizedDescription ?? error.localizedDescription)"
            showSaveAlert = true
        }
    }

    // MARK: - Cargar municipios

    func loadZones() async {
        guard zones.isEmpty, !isLoadingZones else { return }
        await fetchZones()
    }

    func reloadZones() async {
        guard !isLoadingZones else { return }
        zones = []
        await fetchZones()
    }

    private func fetchZones() async {
        isLoadingZones = true
        do {
            let result: WrappedResponse<[ZoneModel]> = try await APIClient.shared.request(
                Endpoint(.get, "/zones")
            )
            print("[Zones] decoded:", result.data.count)
            zones = result.data
            print("[Zones] viewModel:", self.zones.count)
        } catch {
            print("[Zones] ❌ fetchZones error:", error)
        }
        isLoadingZones = false
    }

    // MARK: - Validación local (bloquea el botón Guardar)

    var validationError: String? {
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            return "El título es obligatorio."
        }
        if case .create = mode {
            if selectedZoneId == nil {
                return "Debes seleccionar un municipio."
            }
            let hasSale = !priceSaleStr.trimmingCharacters(in: .whitespaces).isEmpty
            let hasRent = !priceRentStr.trimmingCharacters(in: .whitespaces).isEmpty
            if !hasSale && !hasRent {
                return "Indica al menos un precio de venta o alquiler."
            }
        }
        if let p = Int(priceSaleStr), p <= 0 { return "El precio de venta debe ser mayor que 0." }
        if let p = Int(priceRentStr), p <= 0 { return "El precio de alquiler debe ser mayor que 0." }
        return nil
    }

    var navigationTitle: String {
        switch mode {
        case .create: return "Nueva propiedad"
        case .edit:   return "Editar propiedad"
        }
    }

    var isCreateMode: Bool {
        if case .create = mode { return true }
        return false
    }

    // MARK: - Privados

    private func handleAPIError(_ error: Error) {
        guard let apiError = error as? APIError else {
            saveError     = error.localizedDescription
            showSaveAlert = true
            return
        }
        saveError     = apiError.localizedDescription
        showSaveAlert = true
        for (field, messages) in apiError.validationErrors {
            fieldErrors[field] = messages.first
        }
    }

    private func populateFields(from p: AgencyPropertyDetail) {
        title         = p.title
        description   = p.description   ?? ""
        type          = p.type
        referenceCode = p.referenceCode ?? ""
        address       = p.address       ?? ""
        priceSaleStr  = p.priceSale.map(String.init) ?? ""
        priceRentStr  = p.priceRent.map(String.init) ?? ""
        roomsStr      = p.rooms.map(String.init)         ?? ""
        bathroomsStr  = p.bathrooms.map(String.init)     ?? ""
        surfaceStr    = p.surfaceM2.map(String.init)     ?? ""
        usefulStr     = p.usefulSurfaceM2.map(String.init) ?? ""
        floorStr      = p.floorNumber.map(String.init)   ?? ""
        lat           = p.lat
        lng           = p.lng
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
            lat:             lat,
            lng:             lng,
            priceSale:       Int(priceSaleStr),
            priceRent:       Int(priceRentStr),
            rooms:           Int(roomsStr),
            bathrooms:       Int(bathroomsStr),
            surfaceM2:       Int(surfaceStr),
            usefulSurfaceM2: Int(usefulStr),
            floorNumber:     Int(floorStr),
            referenceCode:   referenceCode.trimmingCharacters(in: .whitespaces).isEmpty ? nil : referenceCode,
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
