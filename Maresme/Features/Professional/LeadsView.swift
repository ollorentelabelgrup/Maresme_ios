import SwiftUI

struct LeadsView: View {
    @State private var vm = LeadsViewModel()

    private let filters: [(label: String, value: String?)] = [
        ("Todos",       nil),
        ("Nuevos",      "new"),
        ("Contactados", "contacted"),
        ("Calificados", "qualified"),
        ("Convertidos", "converted"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            content
        }
        .background(Color.maresmeBackground)
        .navigationTitle("Leads")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
        .refreshable { await vm.reload() }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.label) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color.maresmeSurface)
    }

    private func filterChip(_ filter: (label: String, value: String?)) -> some View {
        let isSelected = vm.selectedStatus == filter.value
        return Button {
            Task { await vm.applyFilter(filter.value) }
        } label: {
            Text(filter.label)
                .font(.maresmeLabelSm)
                .foregroundStyle(isSelected ? .white : Color.maresmeText)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.maresmeBlue : Color.maresmeBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.maresmeDisabled, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if vm.isLoading {
            Spacer()
            ProgressView()
            Spacer()
        } else if let error = vm.errorMessage {
            errorView(error)
        } else if vm.leads.isEmpty {
            emptyState
        } else {
            leadList
        }
    }

    private var leadList: some View {
        List {
            ForEach(vm.leads) { lead in
                NavigationLink {
                    LeadDetailView(leadId: lead.id)
                } label: {
                    LeadRowView(lead: lead)
                }
                .listRowBackground(Color.maresmeSurface)
                .onAppear {
                    if vm.isLastItem(lead) {
                        Task { await vm.loadMore() }
                    }
                }
            }

            if vm.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView().padding(.vertical, 8)
                    Spacer()
                }
                .listRowBackground(Color.maresmeBackground)
            }
        }
        .listStyle(.plain)
        .background(Color.maresmeBackground)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            EmptyStateView(
                icon:    "person.badge.clock",
                title:   "Sin leads",
                message: "No hay leads en este estado todavía."
            )
            Spacer()
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(Color.maresmeWarning)
            Text(message)
                .font(.maresmeBodySm)
                .foregroundStyle(Color.maresmeSubtext)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Reintentar") { Task { await vm.reload() } }
                .buttonStyle(.bordered)
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        LeadsView()
    }
}
