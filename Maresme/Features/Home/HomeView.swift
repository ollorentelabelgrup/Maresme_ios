import SwiftUI

// MARK: - ViewModel

@Observable
final class HomeViewModel {
    var featured:     [PropertyCard] = []
    var isLoading:    Bool           = false
    var errorMessage: String?        = nil

    private let service: PropertyService

    init(service: PropertyService = PropertyService()) {
        self.service = service
    }

    func loadFeatured() async {
        guard featured.isEmpty else { return }
        isLoading = true
        do {
            featured = try await service.featured()
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - HomeView

struct HomeView: View {
    @Environment(SessionManager.self)          private var session
    @Environment(FavoriteStore.self)           private var favoriteStore
    @Environment(AlertStore.self)              private var alertStore
    @Environment(RecommendationStore.self)     private var recommendationStore
    @Environment(NotificationStore.self)       private var notificationStore
    @Environment(NavigationCoordinator.self)   private var coordinator
    @Environment(PushNotificationManager.self) private var pushManager
    @Environment(\.openURL)                    private var openURL

    @State private var viewModel    = HomeViewModel()
    @State private var path         = NavigationPath()
    @State private var showProfile  = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    welcomeSection

                    if !pushManager.isAuthorized {
                        pushStatusSection
                    }

                    // Widget profesional — solo para usuarios con agencia
                    if let agency = session.currentAgency {
                        professionalWidget(agency: agency)
                    }

                    // 1ª prioridad: recomendaciones
                    if recommendationStore.totalCount > 0 {
                        recommendationsWidget
                    }

                    // 2ª prioridad: propiedades destacadas
                    featuredSection

                    // 3ª prioridad: búsquedas rápidas
                    quickSearchSection

                    // 4ª prioridad: actividad reciente
                    if notificationStore.unreadCount > 0 {
                        activityWidget
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color.maresmeBackground)
            .navigationTitle("Inicio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showProfile = true } label: { avatarButton }
                }
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "professional:properties": MyPropertiesView()
                case "professional:leads":      LeadsView()
                case "professional:team":       TeamView()
                case "professional:activity":   ActivityView()
                default:                        PropertyDetailView(slug: destination)
                }
            }
            .navigationDestination(for: PropertySearchFilters.self) { filters in
                PropertyListView()
                    .navigationTitle(filters.navigationTitle)
                    .navigationBarTitleDisplayMode(.large)
                    .environment(PropertySearchStore(initial: filters))
            }
        }
        .onChange(of: coordinator.pendingPropertySlug) { _, slug in
            if let slug {
                path.append(slug)
                coordinator.pendingPropertySlug = nil
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .task { await viewModel.loadFeatured() }
    }

    // MARK: - Avatar toolbar button

    @ViewBuilder
    private var avatarButton: some View {
        if let user = session.currentUser {
            if let avatarUrl = user.avatar.flatMap(URL.init) {
                AsyncImage(url: avatarUrl) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    default:
                        initialsCircle(name: user.name, size: 32)
                    }
                }
            } else {
                initialsCircle(name: user.name, size: 32)
            }
        } else {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 26))
                .foregroundStyle(Color.maresmeBlue)
        }
    }

    private func initialsCircle(name: String, size: CGFloat) -> some View {
        let initials = name.components(separatedBy: " ").prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
            .uppercased()
        return ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.maresmeBlue, Color.maresmeSea],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(initials)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Professional widget

    private func professionalWidget(agency: AgencyModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Panel profesional", icon: "building.2", iconColor: Color.maresmeSea)

            VStack(spacing: 0) {
                // Agency header row
                HStack(spacing: 12) {
                    professionalAgencyLogo(agency)
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(agency.name)
                            .font(.maresmeLabel)
                            .foregroundStyle(Color.maresmeText)
                        if let role = agency.myRole {
                            Text(role)
                                .font(.maresmeCaption)
                                .foregroundStyle(Color.maresmeSea)
                        }
                    }
                    Spacer()
                    NavigationLink {
                        ProfessionalDashboardView()
                    } label: {
                        Text("Ver todo")
                            .font(.maresmeLabelSm)
                            .foregroundStyle(Color.maresmeBlue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                Divider().padding(.horizontal, 14)

                // Quick action row
                HStack(spacing: 0) {
                    professionalQuickAction(icon: "house.and.flag", label: "Propiedades") {
                        path.append("professional:properties")
                    }
                    Divider().frame(height: 40)
                    professionalQuickAction(icon: "person.badge.clock", label: "Leads") {
                        path.append("professional:leads")
                    }
                    Divider().frame(height: 40)
                    professionalQuickAction(icon: "clock.arrow.circlepath", label: "Actividad") {
                        path.append("professional:activity")
                    }
                    Divider().frame(height: 40)
                    professionalQuickAction(icon: "person.3", label: "Equipo") {
                        path.append("professional:team")
                    }
                }
                .padding(.vertical, 4)
            }
            .background(Color.maresmeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.maresmeSea.opacity(0.18), lineWidth: 1)
            )
        }
    }

    private func professionalQuickAction(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.maresmeSea)
                Text(label)
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeSubtext)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func professionalAgencyLogo(_ agency: AgencyModel) -> some View {
        if let urlString = agency.logoUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                default:
                    professionalAgencyInitials(agency.name)
                }
            }
        } else {
            professionalAgencyInitials(agency.name)
        }
    }

    private func professionalAgencyInitials(_ name: String) -> some View {
        let initials = name.components(separatedBy: " ")
            .prefix(2).compactMap { $0.first.map(String.init) }
            .joined().uppercased()
        return ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color.maresmeSea, Color.maresmeBlue],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            Text(initials)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Welcome (simplificado)

    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let user = session.currentUser {
                Text("Hola, \(user.name.components(separatedBy: " ").first ?? user.name)")
                    .font(.maresmeTitle2)
                    .foregroundStyle(Color.maresmeText)
                Text(user.email)
                    .font(.maresmeBodySm)
                    .foregroundStyle(Color.maresmeSubtext)
            } else {
                Text("Bienvenido al Maresme")
                    .font(.maresmeTitle2)
                    .foregroundStyle(Color.maresmeText)
            }
        }
    }

    // MARK: - Push status banner

    private var pushStatusSection: some View {
        HStack(spacing: 12) {
            Image(systemName: pushManager.statusIcon)
                .font(.system(size: 20))
                .foregroundStyle(Color.maresmeWarning)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text("Notificaciones \(pushManager.statusLabel.lowercased())")
                    .font(.maresmeLabel)
                    .foregroundStyle(Color.maresmeText)
                Text("Actívalas para recibir alertas y recomendaciones.")
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeSubtext)
            }
            Spacer()
            if pushManager.authorizationStatus == .denied {
                Button("Ajustes") {
                    if let url = URL(string: "app-settings:") { openURL(url) }
                }
                .font(.maresmeLabelSm)
                .foregroundStyle(Color.maresmeBlue)
            } else if pushManager.authorizationStatus == .notDetermined {
                Button("Activar") {
                    Task { await pushManager.requestPermissions() }
                }
                .font(.maresmeLabelSm)
                .foregroundStyle(Color.maresmeBlue)
            }
        }
        .padding(14)
        .background(Color.maresmeWarning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.maresmeWarning.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Recomendaciones widget

    private var recommendationsWidget: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Recomendadas para ti", icon: "sparkles", iconColor: Color.maresmeBlue)

            HStack(spacing: 12) {
                statCard(
                    icon: "sparkles",
                    iconColor: Color.maresmeBlue,
                    count: recommendationStore.totalCount,
                    label: "compatibles"
                )
                if recommendationStore.unviewedCount > 0 {
                    statCard(
                        icon: "bell.badge",
                        iconColor: Color.maresmeSuccess,
                        count: recommendationStore.unviewedCount,
                        label: "nuevas"
                    )
                }
            }
        }
    }

    // MARK: - Actividad reciente widget

    private var activityWidget: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Actividad reciente", icon: "bell.badge", iconColor: Color.maresmeSuccess)

            if !notificationStore.recentUnread.isEmpty {
                VStack(spacing: 6) {
                    ForEach(notificationStore.recentUnread) { notification in
                        HStack(spacing: 10) {
                            Image(systemName: notification.sfSymbol)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.maresmeSuccess)
                                .frame(width: 20)
                            Text(notification.title)
                                .font(.maresmeBodySm)
                                .foregroundStyle(Color.maresmeText)
                                .lineLimit(1)
                            Spacer()
                            Circle()
                                .fill(Color.maresmeBlue)
                                .frame(width: 6, height: 6)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.maresmeSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            } else {
                statCard(
                    icon: "bell.badge",
                    iconColor: Color.maresmeSuccess,
                    count: notificationStore.unreadCount,
                    label: "sin leer"
                )
            }
        }
    }

    // MARK: - Quick search section

    private struct QuickSearch: Identifiable {
        let id:      String
        let label:   String
        let icon:    String
        let filters: PropertySearchFilters
    }

    private let quickSearches: [QuickSearch] = [
        .init(id: "pisos",     label: "Pisos",     icon: "building.2",  filters: .init(type: "piso")),
        .init(id: "casas",     label: "Casas",     icon: "house",       filters: .init(type: "casa")),
        .init(id: "aticos",    label: "Áticos",    icon: "building",    filters: .init(type: "atico")),
        .init(id: "terrenos",  label: "Terrenos",  icon: "leaf",        filters: .init(type: "terreno")),
        .init(id: "recientes", label: "Recientes", icon: "clock",       filters: .init(sort: "newest")),
        .init(id: "mataro",    label: "Mataró",    icon: "mappin",      filters: .init(zone: "mataro")),
        .init(id: "premia",    label: "Premià",    icon: "mappin",      filters: .init(zone: "premia-de-mar")),
    ]

    private var quickSearchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Buscar propiedades", icon: "magnifyingglass", iconColor: Color.maresmeSubtext)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickSearches) { qs in
                        NavigationLink(value: qs.filters) {
                            HStack(spacing: 6) {
                                Image(systemName: qs.icon).font(.system(size: 13))
                                Text(qs.label).font(.maresmeBodySm)
                            }
                            .foregroundStyle(Color.maresmeBlue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.maresmeBlue.opacity(0.08))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Featured section

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Propiedades destacadas", icon: "star.fill", iconColor: Color.maresmeGold)

            if viewModel.isLoading {
                LoadingView().frame(height: 180)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeError)
                    .padding(.vertical, 8)
            } else if viewModel.featured.isEmpty {
                EmptyStateView(
                    icon:    "house.slash",
                    title:   "Sin destacados",
                    message: "No hay propiedades destacadas en este momento."
                )
                .frame(height: 160)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.featured) { property in
                            NavigationLink(value: property.slug) {
                                FeaturedCard(property: property)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(iconColor)
            Text(title)
                .font(.maresmeLabel)
                .foregroundStyle(Color.maresmeSubtext)
        }
    }

    private func statCard(icon: String, iconColor: Color, count: Int, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(count)")
                    .font(.maresmeLabelLg)
                    .foregroundStyle(Color.maresmeText)
                Text(label)
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeSubtext)
            }
            Spacer()
        }
        .padding(12)
        .background(iconColor.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Featured card

private struct FeaturedCard: View {
    let property: PropertyCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let url = property.mainImage.flatMap(URL.init) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            default:               Color.maresmeBackground
                            }
                        }
                    } else {
                        ZStack {
                            Color.maresmeBackground
                            Image(systemName: "photo").foregroundStyle(Color.maresmeDisabled)
                        }
                    }
                }
                .frame(width: 220, height: 148)
                .clipped()

                if property.isFeatured {
                    Text("Destacado")
                        .font(.maresmeLabelSm)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.maresmeGold)
                        .clipShape(Capsule())
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(property.title)
                    .font(.maresmeBodySm)
                    .foregroundStyle(Color.maresmeText)
                    .lineLimit(2)
                    .frame(width: 220, alignment: .leading)

                if let municipality = property.municipality {
                    Label(municipality.name, systemImage: "mappin.circle")
                        .font(.maresmeCaption)
                        .foregroundStyle(Color.maresmeSubtext)
                }

                HStack(spacing: 8) {
                    if let rooms = property.rooms {
                        iconBadge("bed.double", "\(rooms) hab.")
                    }
                    if let surface = property.surfaceM2 {
                        iconBadge("square.dashed", "\(surface) m²")
                    }
                }

                if let price = property.priceFormatted {
                    Text(price)
                        .font(.maresmeLabel)
                        .foregroundStyle(Color.maresmeBlue)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 220)
        .padding(.bottom, 4)
    }

    private func iconBadge(_ icon: String, _ label: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 10))
            Text(label).font(.maresmeCaption)
        }
        .foregroundStyle(Color.maresmeSubtext)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(SessionManager())
        .environment(FavoriteStore())
        .environment(AlertStore())
        .environment(RecommendationStore())
        .environment(NotificationStore())
        .environment(PushNotificationManager.shared)
        .environment(NavigationCoordinator())
}
