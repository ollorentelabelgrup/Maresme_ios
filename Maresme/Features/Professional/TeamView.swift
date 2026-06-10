import SwiftUI

struct TeamView: View {
    @State private var vm = TeamViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                VStack { Spacer(); ProgressView(); Spacer() }
                    .background(Color.maresmeBackground)
            } else if let error = vm.errorMessage {
                errorView(error)
            } else if vm.members.isEmpty {
                EmptyStateView(
                    icon:    "person.3",
                    title:   "Sin miembros",
                    message: "El equipo no tiene miembros activos todavía."
                )
                .background(Color.maresmeBackground)
            } else {
                memberList
            }
        }
        .navigationTitle("Equipo")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
        .refreshable { await vm.reload() }
    }

    private var memberList: some View {
        List {
            Section {
                ForEach(vm.members) { member in
                    NavigationLink {
                        TeamMemberDetailView(member: member)
                    } label: {
                        TeamMemberRowView(member: member)
                    }
                    .listRowBackground(Color.maresmeSurface)
                }
            } header: {
                HStack {
                    Text("Miembro")
                    Spacer()
                    Text("Total  Abiertos  Conv.")
                        .font(.maresmeCaption)
                        .foregroundStyle(Color.maresmeSubtext)
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(Color.maresmeBackground)
        .scrollContentBackground(.hidden)
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
        .background(Color.maresmeBackground)
    }
}

#Preview {
    NavigationStack {
        TeamView()
    }
}
