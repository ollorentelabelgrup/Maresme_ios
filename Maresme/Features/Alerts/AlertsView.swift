import SwiftUI

struct AlertsView: View {
    @Environment(AlertStore.self)            private var alertStore
    @Environment(NavigationCoordinator.self) private var coordinator
    @State private var viewModel:  AlertsViewModel?
    @State private var path        = NavigationPath()
    @State private var showCreate  = false
    @State private var errorAlert: String? = nil

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel?.isLoading == true && alertStore.alerts.isEmpty {
                    LoadingView(message: "Cargando alertas...")
                } else if alertStore.alerts.isEmpty {
                    emptyState
                } else {
                    alertList
                }
            }
            .navigationTitle("Alertas")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.maresmeBackground)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                AlertFormView(mode: .create)
            }
            .alert("Error", isPresented: Binding(
                get: { errorAlert != nil },
                set: { if !$0 { errorAlert = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorAlert ?? "")
            }
        }
        .onChange(of: coordinator.pendingAlertId) { _, alertId in
            if let alertId {
                path.append(alertId)
                coordinator.pendingAlertId = nil
            }
        }
        .task {
            let vm = AlertsViewModel(store: alertStore)
            viewModel = vm
            await vm.loadIfNeeded()
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        EmptyStateView(
            icon:        "bell.slash",
            title:       "Sin alertas",
            message:     "Crea una alerta para recibir notificaciones cuando aparezcan propiedades que te interesen.",
            action:      { showCreate = true },
            actionTitle: "Crear alerta"
        )
    }

    // MARK: - List

    private var alertList: some View {
        List {
            ForEach(alertStore.alerts) { alert in
                NavigationLink(value: alert.id) {
                    AlertRowView(alert: alert)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.maresmeBackground)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        Task { await viewModel?.toggleActive(alert: alert) }
                    } label: {
                        Label(
                            alert.isActive ? "Pausar" : "Activar",
                            systemImage: alert.isActive ? "pause.circle" : "play.circle"
                        )
                    }
                    .tint(alert.isActive ? Color.maresmeWarning : Color.maresmeSuccess)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        Task { await viewModel?.delete(id: alert.id) }
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(Color.maresmeBackground)
        .refreshable { await viewModel?.refresh() }
        .navigationDestination(for: Int.self) { alertId in
            if let alert = alertStore.alerts.first(where: { $0.id == alertId }) {
                AlertDetailView(alert: alert)
            }
        }
    }
}

// MARK: - Alert row

private struct AlertRowView: View {
    let alert: AlertModel

    var body: some View {
        HStack(spacing: 12) {
            statusIcon
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.name)
                        .font(.maresmeBody)
                        .foregroundStyle(Color.maresmeText)
                    Spacer()
                    if alert.hasNewMatches {
                        Text("\(alert.previewMatchesCount)")
                            .font(.maresmeLabelSm)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.maresmeBlue)
                            .clipShape(Capsule())
                    }
                }
                HStack(spacing: 8) {
                    frequencyLabel
                    if !alert.isActive {
                        Text("Pausada")
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeWarning)
                    }
                }
                if let summary = filterSummary {
                    Text(summary)
                        .font(.maresmeCaption)
                        .foregroundStyle(Color.maresmeSubtext)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .background(Color.maresmeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .opacity(alert.isActive ? 1.0 : 0.6)
    }

    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(alert.isActive ? Color.maresmeBlue.opacity(0.12) : Color.maresmeBackground)
                .frame(width: 40, height: 40)
            Image(systemName: alert.isActive ? "bell.fill" : "bell.slash")
                .font(.system(size: 16))
                .foregroundStyle(alert.isActive ? Color.maresmeBlue : Color.maresmeDisabled)
        }
    }

    private var frequencyLabel: some View {
        let label: String
        switch alert.frequency {
        case "instant": label = "Instantánea"
        case "weekly":  label = "Semanal"
        default:        label = "Diaria"
        }
        return Text(label)
            .font(.maresmeCaption)
            .foregroundStyle(Color.maresmeSubtext)
    }

    private var filterSummary: String? {
        var parts: [String] = []
        if let zone = alert.filters.zone { parts.append(zone.capitalized) }
        if let type = alert.filters.type { parts.append(type) }
        if let max  = alert.filters.priceMax {
            parts.append("máx. \(max.formatted(.number))€")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

#Preview {
    AlertsView()
        .environment(AlertStore())
        .environment(NavigationCoordinator())
}
