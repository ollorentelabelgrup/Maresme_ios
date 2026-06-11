import SwiftUI
import PhotosUI

struct AgencyPropertyEditView: View {
    @State private var vm: AgencyPropertyEditViewModel
    @Environment(\.dismiss) private var dismiss

    private let onSaved: (AgencyPropertyDetail) -> Void

    @State private var showMapPicker      = false
    @State private var photosPickerItems: [PhotosPickerItem] = []

    // MARK: - Init

    init(property: AgencyPropertyDetail, onSaved: @escaping (AgencyPropertyDetail) -> Void) {
        self._vm     = State(initialValue: AgencyPropertyEditViewModel(property: property))
        self.onSaved = onSaved
    }

    init(onCreated: @escaping (AgencyPropertyDetail) -> Void) {
        self._vm     = State(initialValue: AgencyPropertyEditViewModel())
        self.onSaved = onCreated
    }

    // MARK: - Body

    var body: some View {
        Form {
            basicInfoSection
            locationSection
            characteristicsSection
            extrasSection
            classificationSection
            if vm.isCreateMode { photosSection }
        }
        .navigationTitle(vm.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(vm.isSaving)
        .toolbar { saveToolbarItem }
        .task { await vm.loadZones() }
        .sheet(isPresented: $showMapPicker) {
            NavigationStack {
                PropertyLocationPickerView(
                    initialAddress: vm.address,
                    initialLat: vm.lat,
                    initialLng: vm.lng
                ) { lat, lng, resolved in
                    vm.lat = lat
                    vm.lng = lng
                    if !resolved.isEmpty { vm.address = resolved }
                }
            }
        }
        .onChange(of: photosPickerItems) { _, items in
            Task { await loadSelectedPhotos(items) }
        }
        .alert("Error al guardar", isPresented: .constant(vm.saveError != nil)) {
            Button("Aceptar") { vm.saveError = nil }
        } message: {
            Text(vm.saveError ?? "")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var saveToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if vm.isSaving || vm.isUploadingPhotos {
                HStack(spacing: 6) {
                    ProgressView()
                    if vm.isUploadingPhotos {
                        Text("Subiendo fotos…")
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeSubtext)
                    }
                }
            } else {
                Button("Guardar") { saveProperty() }
                    .fontWeight(.semibold)
                    .disabled(vm.validationError != nil)
            }
        }
    }

    // MARK: - Sección 1: Información básica

    private var basicInfoSection: some View {
        Section("Información básica") {

            // Tipo
            LabeledContent("Tipo") {
                Picker("Tipo", selection: $vm.type) {
                    ForEach(propertyTypes, id: \.0) { value, label in
                        Text(label).tag(value)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            // Título
            VStack(alignment: .leading, spacing: 3) {
                TextField("Título *", text: $vm.title)
                fieldError("title")
            }

            // Referencia
            TextField("Referencia (opcional)", text: $vm.referenceCode)

            // Municipio
            VStack(alignment: .leading, spacing: 3) {
                if vm.isLoadingZones {
                    LabeledContent(vm.isCreateMode ? "Municipio *" : "Municipio") {
                        ProgressView().scaleEffect(0.7)
                    }
                } else if !vm.zones.isEmpty {
                    LabeledContent(vm.isCreateMode ? "Municipio *" : "Municipio") {
                        Picker("Municipio", selection: $vm.selectedZoneId) {
                            Text("Seleccionar…").tag(Optional<Int>.none)
                            ForEach(vm.zones) { zone in
                                Text(zone.name).tag(Optional(zone.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }
                fieldError("zone_id")
            }

            // Precio venta
            VStack(alignment: .leading, spacing: 3) {
                TextField("Precio venta (€)", text: $vm.priceSaleStr)
                    .keyboardType(.numberPad)
                fieldError("price_sale")
            }

            // Precio alquiler
            VStack(alignment: .leading, spacing: 3) {
                TextField("Precio alquiler (€/mes)", text: $vm.priceRentStr)
                    .keyboardType(.numberPad)
                fieldError("price_rent")
            }

            // Descripción
            VStack(alignment: .leading, spacing: 4) {
                Text("Descripción")
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeSubtext)
                TextEditor(text: $vm.description)
                    .frame(minHeight: 88)
            }
        }
    }

    // MARK: - Sección 2: Ubicación

    private var locationSection: some View {
        Section("Ubicación") {
            VStack(alignment: .leading, spacing: 3) {
                TextField("Dirección", text: $vm.address)
                fieldError("address")
            }

            Button { showMapPicker = true } label: {
                HStack {
                    Image(systemName: vm.lat != nil ? "mappin.circle.fill" : "mappin.circle")
                        .foregroundStyle(vm.lat != nil ? Color.maresmeSuccess : Color.maresmeBlue)
                    Text(vm.lat != nil ? "Ubicación seleccionada" : "Seleccionar en el mapa")
                        .foregroundStyle(vm.lat != nil ? Color.maresmeSuccess : Color.maresmeBlue)
                    Spacer()
                    if let lat = vm.lat, let lng = vm.lng {
                        Text(String(format: "%.4f, %.4f", lat, lng))
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeSubtext)
                    }
                }
            }
        }
    }

    // MARK: - Sección 3: Características

    private var characteristicsSection: some View {
        Section("Características") {
            TextField("Habitaciones", text: $vm.roomsStr).keyboardType(.numberPad)
            TextField("Baños", text: $vm.bathroomsStr).keyboardType(.numberPad)
            TextField("Superficie (m²)", text: $vm.surfaceStr).keyboardType(.numberPad)
            TextField("Superficie útil (m²)", text: $vm.usefulStr).keyboardType(.numberPad)
            TextField("Planta", text: $vm.floorStr).keyboardType(.numberPad)
        }
    }

    // MARK: - Sección 4: Extras

    private var extrasSection: some View {
        Section("Extras") {
            Toggle("Piscina",       isOn: $vm.hasPool)
            Toggle("Jardín",        isOn: $vm.hasGarden)
            Toggle("Terraza",       isOn: $vm.hasTerrace)
            Toggle("Ascensor",      isOn: $vm.hasElevator)
            Toggle("Parking",       isOn: $vm.hasParking)
            Toggle("Trastero",      isOn: $vm.hasStorageRoom)
            Toggle("Vistas al mar", isOn: $vm.hasSeaView)
        }
    }

    // MARK: - Sección 5: Clasificación

    private var classificationSection: some View {
        Section("Clasificación") {
            Toggle("Obra nueva", isOn: $vm.isNewBuild)
            Toggle("Exclusiva",  isOn: $vm.isExclusive)
            Toggle("Destacada",  isOn: $vm.isFeatured)
        }
    }

    // MARK: - Sección 6: Fotos (solo en creación)

    private var photosSection: some View {
        Section("Fotos") {
            PhotosPicker(
                selection: $photosPickerItems,
                maxSelectionCount: 20,
                matching: .images
            ) {
                Label("Seleccionar fotos", systemImage: "photo.badge.plus")
                    .foregroundStyle(Color.maresmeBlue)
            }

            if !vm.pendingPhotos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(vm.pendingPhotos.indices, id: \.self) { i in
                            photoThumbnail(index: i)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                Text(photoCountLabel)
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeSubtext)
            }
        }
    }

    private var photoCountLabel: String {
        let n = vm.pendingPhotos.count
        return "\(n) foto\(n == 1 ? "" : "s") seleccionada\(n == 1 ? "" : "s"). La primera será la foto principal."
    }

    private func photoThumbnail(index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: vm.pendingPhotos[index])
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button { vm.removePendingPhoto(at: index) } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Circle())
            }
            .offset(x: 6, y: -6)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func fieldError(_ key: String) -> some View {
        if let msg = vm.fieldErrors[key] {
            Text(msg)
                .font(.maresmeCaption)
                .foregroundStyle(Color.maresmeError)
        }
    }

    private func saveProperty() {
        Task {
            do {
                let saved = try await vm.save()
                onSaved(saved)
                dismiss()
            } catch {
                // Error expuesto mediante vm.saveError y vm.fieldErrors
            }
        }
    }

    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        for item in items {
            guard let data  = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { continue }
            vm.addPendingPhoto(image)
        }
        // Reset para permitir añadir más fotos en sucesivas selecciones
        photosPickerItems = []
    }

    // MARK: - Datos estáticos

    private let propertyTypes: [(String, String)] = [
        ("piso",    "Piso"),
        ("casa",    "Casa"),
        ("local",   "Local"),
        ("oficina", "Oficina"),
        ("garaje",  "Garaje"),
        ("terreno", "Terreno"),
        ("nave",    "Nave industrial"),
    ]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AgencyPropertyEditView(
            property: AgencyPropertyDetail(
                id: "01HX",
                slug: "piso-ejemplo",
                title: "Piso de ejemplo",
                referenceCode: "REF-001",
                description: nil,
                type: "piso",
                status: "draft",
                isActive: false,
                priceSale: 250000,
                priceRent: nil,
                price: nil,
                priceType: nil,
                surfaceM2: 85,
                usefulSurfaceM2: nil,
                rooms: 3,
                bathrooms: 2,
                floorNumber: nil,
                hasElevator: nil,
                hasTerrace: nil,
                hasParking: nil,
                hasPool: nil,
                hasStorageRoom: nil,
                hasGarden: nil,
                hasSeaView: nil,
                isNewBuild: nil,
                isExclusive: nil,
                isFeatured: nil,
                municipality: nil,
                zoneId: nil,
                address: nil,
                lat: nil,
                lng: nil,
                heroImage: nil,
                photos: [],
                leadsCount: 0,
                healthScore: nil,
                createdAt: nil,
                updatedAt: nil
            ),
            onSaved: { _ in }
        )
    }
}
