import SwiftUI

// MARK: - SearchFiltersView
// Sheet de filtros para GET /api/v1/properties.
// Trabaja sobre una copia local (draft) y llama onApply al confirmar.

struct SearchFiltersView: View {
    let onApply: (PropertySearchFilters) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: PropertySearchFilters

    init(
        currentFilters: PropertySearchFilters = PropertySearchFilters(),
        onApply: @escaping (PropertySearchFilters) -> Void
    ) {
        self.onApply = onApply
        self._draft  = State(initialValue: currentFilters)
    }

    var body: some View {
        NavigationStack {
            Form {
                municipalitySection
                typeSection
                priceSection
                featuresSection
                surfaceSection
                sortSection
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Limpiar") {
                        draft = PropertySearchFilters()
                    }
                    .foregroundStyle(Color.maresmeError)
                    .disabled(draft.isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Aplicar") {
                        onApply(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
    }

    // MARK: - Municipio

    private var municipalitySection: some View {
        Section("Municipio") {
            Picker("Municipio", selection: Binding(
                get: { draft.zone ?? "" },
                set: { draft.zone = $0.isEmpty ? nil : $0 }
            )) {
                Text("Cualquier municipio").tag("")
                ForEach(PropertySearchFilters.Municipality.all) { m in
                    Text(m.name).tag(m.slug)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }

    // MARK: - Tipo

    private var typeSection: some View {
        Section("Tipo de propiedad") {
            Picker("Tipo", selection: Binding(
                get: { draft.type ?? "" },
                set: { draft.type = $0.isEmpty ? nil : $0 }
            )) {
                Text("Cualquier tipo").tag("")
                ForEach(PropertySearchFilters.PropertyType.all) { t in
                    Label(t.label, systemImage: t.icon).tag(t.value)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }

    // MARK: - Precio

    private var priceSection: some View {
        Section("Precio") {
            HStack {
                Text("Mínimo")
                Spacer()
                TextField("Sin mínimo", value: $draft.priceMin, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 110)
                if draft.priceMin != nil {
                    Text("€")
                        .foregroundStyle(Color.maresmeSubtext)
                }
            }
            HStack {
                Text("Máximo")
                Spacer()
                TextField("Sin límite", value: $draft.priceMax, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 110)
                if draft.priceMax != nil {
                    Text("€")
                        .foregroundStyle(Color.maresmeSubtext)
                }
            }
        }
    }

    // MARK: - Características (hab. y baños)

    private var featuresSection: some View {
        Section("Características") {
            Stepper(
                roomsLabel,
                value: Binding(
                    get: { draft.rooms ?? 0 },
                    set: { draft.rooms = $0 == 0 ? nil : $0 }
                ),
                in: 0...10
            )
            Stepper(
                bathroomsLabel,
                value: Binding(
                    get: { draft.bathrooms ?? 0 },
                    set: { draft.bathrooms = $0 == 0 ? nil : $0 }
                ),
                in: 0...5
            )
        }
    }

    private var roomsLabel: String {
        guard let r = draft.rooms else { return "Habitaciones: cualquiera" }
        return "Habitaciones: ≥ \(r)"
    }

    private var bathroomsLabel: String {
        guard let b = draft.bathrooms else { return "Baños: cualquiera" }
        return "Baños: ≥ \(b)"
    }

    // MARK: - Superficie

    private var surfaceSection: some View {
        Section("Superficie (m²)") {
            HStack {
                Text("Mínima")
                Spacer()
                TextField("Sin mínimo", value: $draft.surfaceMin, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
                if draft.surfaceMin != nil {
                    Text("m²")
                        .foregroundStyle(Color.maresmeSubtext)
                }
            }
            HStack {
                Text("Máxima")
                Spacer()
                TextField("Sin límite", value: $draft.surfaceMax, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
                if draft.surfaceMax != nil {
                    Text("m²")
                        .foregroundStyle(Color.maresmeSubtext)
                }
            }
        }
    }

    // MARK: - Ordenar

    private var sortSection: some View {
        Section("Ordenar por") {
            ForEach(PropertySearchFilters.SortOption.all) { opt in
                HStack {
                    Text(opt.label)
                    Spacer()
                    if draft.sort == opt.value {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.maresmeBlue)
                            .fontWeight(.semibold)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { draft.sort = opt.value }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SearchFiltersView(
        currentFilters: PropertySearchFilters(type: "piso", priceMax: 450_000, rooms: 3),
        onApply:        { _ in }
    )
}
