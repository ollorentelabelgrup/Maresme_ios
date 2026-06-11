import SwiftUI

struct AlertDetailView: View {
    let alert: AlertModel
    @Environment(AlertStore.self)   private var alertStore
    @Environment(FavoriteStore.self) private var favoriteStore
    @State private var viewModel: AlertDetailViewModel?
    @State private var showEdit      = false
    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let current = viewModel?.currentAlert(fallback: alert) ?? alert
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection(current)
                Divider()
                filtersSection(current)
                if !(viewModel?.matches.isEmpty ?? true) || viewModel?.isLoadingMatches == true {
                    Divider()
                    matchesSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(Color.maresmeBackground)
        .navigationTitle(current.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showEdit = true
                } label: {
                    Image(systemName: "pencil")
                }
                Menu {
                    Button {
                        Task { await viewModel?.toggleActive(current: current) }
                    } label: {
                        Label(
                            current.isActive ? "Pausar alerta" : "Reactivar alerta",
                            systemImage: current.isActive ? "pause.circle" : "play.circle"
                        )
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Eliminar alerta", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            AlertFormView(mode: .edit(current))
        }
        .confirmationDialog(
            "Eliminar alerta",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                Task {
                    try? await viewModel?.delete()
                    dismiss()
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se eliminará «\(current.name)» de forma permanente.")
        }
        .task {
            let vm = AlertDetailViewModel(alertId: alert.id, store: alertStore)
            viewModel = vm
            await vm.loadMatches()
        }
    }

    // MARK: - Header

    private func headerSection(_ a: AlertModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                statusTag(a)
                frequencyTag(a)
                Spacer()
                if a.hasNewMatches {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("\(a.previewMatchesCount) coincidencias")
                            .font(.maresmeLabel)
                    }
                    .foregroundStyle(Color.maresmeBlue)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                if let lastMatch = a.lastMatchAt {
                    Label("Última coincidencia: \(lastMatch.formatted(date: .abbreviated, time: .omitted))",
                          systemImage: "clock")
                        .font(.maresmeCaption)
                        .foregroundStyle(Color.maresmeSubtext)
                }
                if a.matchesCount > 0 {
                    Label("\(a.matchesCount) propiedades notificadas en total",
                          systemImage: "envelope")
                        .font(.maresmeCaption)
                        .foregroundStyle(Color.maresmeSubtext)
                }
            }
        }
    }

    private func statusTag(_ a: AlertModel) -> some View {
        Text(a.isActive ? "Activa" : "Pausada")
            .font(.maresmeLabelSm)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(a.isActive ? Color.maresmeSuccess : Color.maresmeWarning)
            .clipShape(Capsule())
    }

    private func frequencyTag(_ a: AlertModel) -> some View {
        let label: String
        switch a.frequency {
        case "instant": label = "Instantánea"
        case "weekly":  label = "Semanal"
        default:        label = "Diaria"
        }
        return Text(label)
            .font(.maresmeLabelSm)
            .foregroundStyle(Color.maresmeSubtext)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.maresmeBackground)
            .clipShape(Capsule())
    }

    // MARK: - Filters

    private func filtersSection(_ a: AlertModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filtros configurados")
                .font(.maresmeLabel)
                .foregroundStyle(Color.maresmeSubtext)

            let f = a.filters
            let items: [(String, String, String)] = [
                ("Zone", "mappin.circle",  f.zone?.capitalized ?? ""),
                ("Tipo", "house",          f.type ?? ""),
                ("Precio máx.", "tag",     f.priceMax.map { "\($0.formatted(.number))€" } ?? ""),
                ("Habitaciones", "bed.double", f.rooms.map { "≥ \($0)" } ?? ""),
                ("Baños", "shower",        f.bathrooms.map { "≥ \($0)" } ?? ""),
            ].filter { !$0.2.isEmpty }

            if items.isEmpty {
                Text("Sin filtros específicos — coincide con todas las propiedades.")
                    .font(.maresmeBodySm)
                    .foregroundStyle(Color.maresmeSubtext)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(items, id: \.0) { label, icon, value in
                        HStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.maresmeBlue)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(label)
                                    .font(.maresmeCaption)
                                    .foregroundStyle(Color.maresmeSubtext)
                                Text(value)
                                    .font(.maresmeBodySm)
                                    .foregroundStyle(Color.maresmeText)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.maresmeSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    // MARK: - Matches

    private var matchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coincidencias actuales")
                .font(.maresmeLabel)
                .foregroundStyle(Color.maresmeSubtext)

            if viewModel?.isLoadingMatches == true && viewModel?.matches.isEmpty == true {
                LoadingView()
                    .frame(height: 120)
            } else if let error = viewModel?.matchesError {
                Text(error)
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeError)
            } else if viewModel?.matches.isEmpty == true {
                Text("Sin coincidencias con los filtros actuales.")
                    .font(.maresmeBodySm)
                    .foregroundStyle(Color.maresmeSubtext)
                    .padding(.vertical, 8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel?.matches ?? []) { property in
                        NavigationLink(value: property.slug) {
                            PropertyRowView(property: property)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            if property.id == viewModel?.matches.last?.id {
                                Task { await viewModel?.loadMoreMatches() }
                            }
                        }
                    }
                    if viewModel?.isLoadingMoreMatches == true {
                        ProgressView().padding(.vertical, 8)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AlertDetailView(alert: PreviewData.alertModel)
            .environment(AlertStore())
            .environment(FavoriteStore())
    }
}
