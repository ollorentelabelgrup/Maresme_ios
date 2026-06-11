import SwiftUI

enum AlertFormMode {
    case create
    case edit(AlertModel)

    var title: String {
        switch self {
        case .create: return "Nueva alerta"
        case .edit:   return "Editar alerta"
        }
    }

    var alertModel: AlertModel? {
        if case .edit(let a) = self { return a }
        return nil
    }
}

struct AlertFormView: View {
    let mode: AlertFormMode

    @Environment(AlertStore.self) private var alertStore
    @Environment(\.dismiss)       private var dismiss

    // Form fields
    @State private var name:      String = ""
    @State private var frequency: String = "daily"
    @State private var zone:      String = ""
    @State private var type:      String = ""
    @State private var priceMax:  String = ""
    @State private var rooms:     Int    = 0
    @State private var bathrooms: Int    = 0

    @State private var isSaving   = false
    @State private var saveError: String? = nil

    private let frequencies: [(String, String)] = [
        ("instant", "Instantánea"),
        ("daily",   "Diaria"),
        ("weekly",  "Semanal"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Nombre de la alerta") {
                    TextField("Ej. Pisos en Alella hasta 300k", text: $name)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Frecuencia de notificación") {
                    Picker("Frecuencia", selection: $frequency) {
                        ForEach(frequencies, id: \.0) { value, label in
                            Text(label).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Filtros (opcionales)") {
                    Picker("Municipio", selection: $zone) {
                        Text("Cualquier municipio").tag("")
                        ForEach(PropertySearchFilters.Municipality.all) { m in
                            Text(m.name).tag(m.slug)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    Picker("Tipo de propiedad", selection: $type) {
                        Text("Cualquier tipo").tag("")
                        ForEach(PropertySearchFilters.PropertyType.all) { t in
                            Label(t.label, systemImage: t.icon).tag(t.value)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    HStack {
                        Text("Precio máximo")
                        Spacer()
                        TextField("Sin límite", text: $priceMax)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                        if !priceMax.isEmpty {
                            Text("€")
                                .foregroundStyle(Color.maresmeSubtext)
                        }
                    }

                    Stepper("Habitaciones: \(rooms == 0 ? "cualquiera" : "≥ \(rooms)")",
                            value: $rooms, in: 0...10)

                    Stepper("Baños: \(bathrooms == 0 ? "cualquiera" : "≥ \(bathrooms)")",
                            value: $bathrooms, in: 0...5)
                }

                if let error = saveError {
                    Section {
                        Text(error)
                            .foregroundStyle(Color.maresmeError)
                            .font(.maresmeCaption)
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(mode.alertModel == nil ? "Crear" : "Guardar")
                                .bold()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .onAppear { populateIfEditing() }
        }
    }

    // MARK: - Populate for edit mode

    private func populateIfEditing() {
        guard let a = mode.alertModel else { return }
        name      = a.name
        frequency = a.frequency
        zone      = a.filters.zone ?? ""
        type      = a.filters.type ?? ""
        priceMax  = a.filters.priceMax.map { String($0) } ?? ""
        rooms     = a.filters.rooms ?? 0
        bathrooms = a.filters.bathrooms ?? 0
    }

    // MARK: - Save

    private func save() async {
        isSaving  = true
        saveError = nil

        let filters = AlertFiltersRequest(
            zone:       zone.isEmpty      ? nil : zone,
            type:       type.isEmpty      ? nil : type,
            priceMin:   nil,
            priceMax:   Int(priceMax),
            rooms:      rooms     > 0     ? rooms     : nil,
            bathrooms:  bathrooms > 0     ? bathrooms : nil,
            surfaceMin: nil,
            surfaceMax: nil
        )

        do {
            if let existing = mode.alertModel {
                let request = UpdateAlertRequest(
                    name:      name.trimmingCharacters(in: .whitespaces),
                    frequency: frequency,
                    filters:   filters
                )
                _ = try await alertStore.update(id: existing.id, request: request)
            } else {
                let request = CreateAlertRequest(
                    name:      name.trimmingCharacters(in: .whitespaces),
                    frequency: frequency,
                    filters:   filters
                )
                _ = try await alertStore.create(request: request)
            }
            dismiss()
        } catch {
            saveError = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isSaving = false
    }
}

#Preview("Crear") {
    AlertFormView(mode: .create)
        .environment(AlertStore())
}

#Preview("Editar") {
    AlertFormView(mode: .edit(PreviewData.alertModel))
        .environment(AlertStore())
}
