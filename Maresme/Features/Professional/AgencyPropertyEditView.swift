import SwiftUI

struct AgencyPropertyEditView: View {
    @State private var vm: AgencyPropertyEditViewModel
    @Environment(\.dismiss) private var dismiss

    private let onSaved: (AgencyPropertyDetail) -> Void

    init(property: AgencyPropertyDetail, onSaved: @escaping (AgencyPropertyDetail) -> Void) {
        self._vm     = State(initialValue: AgencyPropertyEditViewModel(property: property))
        self.onSaved = onSaved
    }

    var body: some View {
        Form {
            basicSection
            priceSection
            featuresSection
            locationSection
            extrasSection
            classificationSection
        }
        .navigationTitle("Editar propiedad")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(vm.isSaving)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if vm.isSaving {
                    ProgressView()
                } else {
                    Button("Guardar") { saveProperty() }
                        .fontWeight(.semibold)
                        .disabled(vm.validationError != nil)
                }
            }
        }
        .task { await vm.loadZones() }
        .alert("Error al guardar", isPresented: .constant(vm.saveError != nil)) {
            Button("Aceptar") { vm.saveError = nil }
        } message: {
            Text(vm.saveError ?? "")
        }
    }

    // MARK: - Básico

    private var basicSection: some View {
        Section("Básico") {
            LabeledContent("Tipo") {
                Picker("Tipo", selection: $vm.type) {
                    ForEach(propertyTypes, id: \.0) { type, label in
                        Text(label).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            TextField("Título *", text: $vm.title)

            VStack(alignment: .leading, spacing: 4) {
                Text("Descripción")
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeSubtext)
                TextEditor(text: $vm.description)
                    .frame(minHeight: 88)
            }
        }
    }

    // MARK: - Precio

    private var priceSection: some View {
        Section("Precio") {
            TextField("Precio venta (€)", text: $vm.priceSaleStr)
                .keyboardType(.numberPad)
            TextField("Precio alquiler (€/mes)", text: $vm.priceRentStr)
                .keyboardType(.numberPad)
        }
    }

    // MARK: - Características

    private var featuresSection: some View {
        Section("Características") {
            TextField("Habitaciones", text: $vm.roomsStr)
                .keyboardType(.numberPad)
            TextField("Baños", text: $vm.bathroomsStr)
                .keyboardType(.numberPad)
            TextField("Superficie (m²)", text: $vm.surfaceStr)
                .keyboardType(.numberPad)
            TextField("Superficie útil (m²)", text: $vm.usefulStr)
                .keyboardType(.numberPad)
            TextField("Planta", text: $vm.floorStr)
                .keyboardType(.numberPad)
        }
    }

    // MARK: - Ubicación

    private var locationSection: some View {
        Section("Ubicación") {
            TextField("Dirección", text: $vm.address)

            if !vm.zones.isEmpty {
                LabeledContent("Zona") {
                    Picker("Zona", selection: $vm.selectedZoneId) {
                        Text("Sin zona").tag(Optional<Int>.none)
                        ForEach(vm.zones) { zone in
                            Text(zone.name).tag(Optional(zone.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            } else {
                LabeledContent("Zona ID") {
                    if vm.isLoadingZones {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Text(vm.selectedZoneId.map(String.init) ?? "No asignada")
                            .foregroundStyle(Color.maresmeSubtext)
                    }
                }
            }

            TextField("Latitud", text: $vm.latStr)
                .keyboardType(.decimalPad)
            TextField("Longitud", text: $vm.lngStr)
                .keyboardType(.decimalPad)
        }
    }

    // MARK: - Extras

    private var extrasSection: some View {
        Section("Extras") {
            Toggle("Ascensor",   isOn: $vm.hasElevator)
            Toggle("Terraza",    isOn: $vm.hasTerrace)
            Toggle("Parking",    isOn: $vm.hasParking)
            Toggle("Piscina",    isOn: $vm.hasPool)
            Toggle("Trastero",   isOn: $vm.hasStorageRoom)
            Toggle("Jardín",     isOn: $vm.hasGarden)
            Toggle("Vistas mar", isOn: $vm.hasSeaView)
        }
    }

    // MARK: - Clasificación

    private var classificationSection: some View {
        Section("Clasificación") {
            Toggle("Obra nueva",  isOn: $vm.isNewBuild)
            Toggle("Exclusiva",   isOn: $vm.isExclusive)
            Toggle("Destacada",   isOn: $vm.isFeatured)
        }
    }

    // MARK: - Save

    private func saveProperty() {
        Task {
            do {
                let updated = try await vm.save()
                onSaved(updated)
                dismiss()
            } catch {
                // error shown via alert binding
            }
        }
    }

    // MARK: - Data

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

#Preview {
    NavigationStack {
        AgencyPropertyEditView(
            property: AgencyPropertyDetail(
                id: "01HX",
                slug: "piso-ejemplo",
                title: "Piso de ejemplo",
                referenceCode: nil,
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
