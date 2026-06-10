import SwiftUI

struct ProfessionalDashboardView: View {
    @Environment(SessionManager.self) private var session
    @Environment(\.openURL)           private var openURL

    @State private var vm = ProfessionalDashboardViewModel()

    var body: some View {
        List {
            if let agency = session.currentAgency {
                agencyHeaderSection(agency)
            }

            statsSection

            quickActionsSection

            if let agency = session.currentAgency {
                agencyContactSection(agency)
            }
        }
        .listStyle(.insetGrouped)
        .background(Color.maresmeBackground)
        .scrollContentBackground(.hidden)
        .navigationTitle("Mi inmobiliaria")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
        .refreshable { await vm.reload() }
    }

    // MARK: - Agency header

    private func agencyHeaderSection(_ agency: AgencyModel) -> some View {
        Section {
            VStack(spacing: 16) {
                agencyLogo(agency)
                    .frame(width: 72, height: 72)

                VStack(spacing: 4) {
                    Text(agency.name)
                        .font(.maresmeTitle3)
                        .foregroundStyle(Color.maresmeText)
                        .multilineTextAlignment(.center)
                    if let myRole = agency.myRole {
                        Text(myRole)
                            .font(.maresmeLabelSm)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(roleColor(myRole))
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .listRowBackground(Color.maresmeBackground)
            .listRowInsets(EdgeInsets())
        }
    }

    // MARK: - Stats

    @ViewBuilder
    private var statsSection: some View {
        Section("Resumen del negocio") {
            if vm.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 8)
                    Spacer()
                }
                .listRowBackground(Color.maresmeBackground)
                .listRowInsets(EdgeInsets())
            } else if let error = vm.errorMessage {
                Text(error)
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeError)
            } else {
                statsGrid
                    .listRowBackground(Color.maresmeBackground)
                    .listRowInsets(EdgeInsets())
            }
        }
    }

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            statCard(
                value:    vm.stats?.activeProperties ?? 0,
                label:    "Activas",
                icon:     "house.fill",
                color:    .maresmeSuccess
            )
            statCard(
                value:    vm.stats?.pendingProperties ?? 0,
                label:    "Borrador",
                icon:     "clock.fill",
                color:    .maresmeSubtext
            )
            statCard(
                value:    vm.stats?.newLeads ?? 0,
                label:    "Leads nuevos",
                icon:     "person.crop.circle.badge.plus",
                color:    .maresmeBlue
            )
            statCard(
                value:    vm.stats?.pendingLeads ?? 0,
                label:    "Leads pendientes",
                icon:     "person.badge.clock",
                color:    .maresmeWarning
            )
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }

    private func statCard(value: Int, label: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                Spacer()
            }
            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.maresmeText)
            Text(label)
                .font(.maresmeCaption)
                .foregroundStyle(Color.maresmeSubtext)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.maresmeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Quick actions

    private var quickActionsSection: some View {
        Section("Panel de gestión") {
            NavigationLink {
                MyPropertiesView()
            } label: {
                Label("Propiedades", systemImage: "house.and.flag")
            }
            NavigationLink {
                LeadsView()
            } label: {
                Label("Leads", systemImage: "person.badge.clock")
            }
            NavigationLink {
                ActivityView()
            } label: {
                Label("Actividad", systemImage: "clock.arrow.circlepath")
            }
            NavigationLink {
                TeamView()
            } label: {
                Label("Equipo", systemImage: "person.3")
            }
        }
    }

    // MARK: - Contact info

    private func agencyContactSection(_ agency: AgencyModel) -> some View {
        Section("Datos de contacto") {
            if let phone = agency.phone {
                LabeledContent("Teléfono", value: phone)
            }
            if let email = agency.email {
                LabeledContent("Email", value: email)
            }
            if let address = agency.address {
                LabeledContent("Dirección", value: address)
            }
            if let website = agency.website, let url = URL(string: website) {
                Button {
                    openURL(url)
                } label: {
                    HStack {
                        Text("Web")
                            .foregroundStyle(Color.maresmeText)
                        Spacer()
                        Text(website)
                            .foregroundStyle(Color.maresmeBlue)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func agencyLogo(_ agency: AgencyModel) -> some View {
        if let urlString = agency.logoUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                default:
                    agencyInitialsView(agency.name)
                }
            }
        } else {
            agencyInitialsView(agency.name)
        }
    }

    private func agencyInitialsView(_ name: String) -> some View {
        let initials = name.components(separatedBy: " ")
            .prefix(2).compactMap { $0.first.map(String.init) }
            .joined().uppercased()
        return ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color.maresmeBlue, Color.maresmeSea],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            Text(initials)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private func roleColor(_ role: String) -> Color {
        switch role.lowercased() {
        case "owner":   return Color.maresmeError
        case "manager": return Color.maresmeSea
        default:        return Color.maresmeBlue
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfessionalDashboardView()
            .environment(SessionManager())
    }
}
