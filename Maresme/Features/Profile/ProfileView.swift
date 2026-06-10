import SwiftUI

// MARK: - ProfileView
// Presentado como .sheet desde HomeView (toolbar avatar).
// Contiene: avatar header, Mi perfil, Notificaciones, Sesiones activas, Cerrar sesión.

struct ProfileView: View {
    @Environment(SessionManager.self)          private var session
    @Environment(PushNotificationManager.self) private var pushManager
    @Environment(\.openURL)                    private var openURL
    @Environment(\.dismiss)                    private var dismiss

    var body: some View {
        NavigationStack {
            List {
                avatarSection
                menuSection
                signOutSection
            }
            .listStyle(.insetGrouped)
            .background(Color.maresmeBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle("Mi cuenta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .fontWeight(.medium)
                }
            }
            .task { await pushManager.refreshStatus() }
        }
    }

    // MARK: - Avatar section

    private var avatarSection: some View {
        Section {
            VStack(spacing: 14) {
                avatarCircle
                    .frame(width: 84, height: 84)

                if let user = session.currentUser {
                    VStack(spacing: 4) {
                        Text(user.name)
                            .font(.maresmeTitle3)
                            .foregroundStyle(Color.maresmeText)
                        Text(user.email)
                            .font(.maresmeBodySm)
                            .foregroundStyle(Color.maresmeSubtext)
                        Text(roleLabel(user.role))
                            .font(.maresmeLabelSm)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(roleColor(user.role))
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

    @ViewBuilder
    private var avatarCircle: some View {
        if let user = session.currentUser,
           let avatarUrl = user.avatar.flatMap(URL.init) {
            AsyncImage(url: avatarUrl) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    initialsCircle(name: user.name)
                }
            }
            .clipShape(Circle())
        } else if let user = session.currentUser {
            initialsCircle(name: user.name)
        } else {
            Circle()
                .fill(Color.maresmeBlue.opacity(0.15))
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Color.maresmeBlue)
                }
        }
    }

    private func initialsCircle(name: String) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.maresmeBlue, Color.maresmeSea],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(initials(from: name))
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Menu section

    private var menuSection: some View {
        Group {
            // Sección profesional (solo si el usuario pertenece a una agencia)
            if session.isProfessionalUser {
                professionalSection
            }

            // Sección personal
            Section {
                NavigationLink {
                    if let user = session.currentUser {
                        UserProfileDetailView(user: user)
                    }
                } label: {
                    Label("Mi perfil", systemImage: "person.circle")
                }

                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    HStack {
                        Label("Notificaciones", systemImage: "bell")
                        Spacer()
                        pushStatusChip
                    }
                }

                NavigationLink {
                    SessionsPlaceholderView()
                } label: {
                    Label("Sesiones activas", systemImage: "iphone")
                }
            }
        }
    }

    private var professionalSection: some View {
        Section {
            if let agency = session.currentAgency {
                NavigationLink {
                    ProfessionalDashboardView()
                } label: {
                    HStack(spacing: 12) {
                        agencyLogoSmall(agency)
                            .frame(width: 36, height: 36)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(agency.name)
                                .font(.maresmeBodySm)
                                .foregroundStyle(Color.maresmeText)
                            if let role = agency.myRole {
                                Text(role)
                                    .font(.maresmeCaption)
                                    .foregroundStyle(Color.maresmeSubtext)
                            }
                        }
                    }
                }
            }

            NavigationLink {
                MyPropertiesView()
            } label: {
                Label("Mis propiedades", systemImage: "house.and.flag")
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
        } header: {
            Text("Inmobiliaria")
        }
    }

    @ViewBuilder
    private func agencyLogoSmall(_ agency: AgencyModel) -> some View {
        if let urlString = agency.logoUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                default:
                    agencyInitialsSmall(agency.name)
                }
            }
        } else {
            agencyInitialsSmall(agency.name)
        }
    }

    private func agencyInitialsSmall(_ name: String) -> some View {
        let initials = name.components(separatedBy: " ")
            .prefix(2).compactMap { $0.first.map(String.init) }
            .joined().uppercased()
        return ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color.maresmeBlue, Color.maresmeSea],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            Text(initials)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var pushStatusChip: some View {
        Text(pushManager.isAuthorized ? "Activas" : "Inactivas")
            .font(.maresmeLabelSm)
            .foregroundStyle(pushManager.isAuthorized ? Color.maresmeSuccess : Color.maresmeWarning)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                (pushManager.isAuthorized ? Color.maresmeSuccess : Color.maresmeWarning)
                    .opacity(0.12)
            )
            .clipShape(Capsule())
    }

    // MARK: - Sign out section

    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                session.signOut()
                dismiss()
            } label: {
                Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    // MARK: - Helpers

    private func initials(from name: String) -> String {
        let parts = name.components(separatedBy: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func roleLabel(_ role: String) -> String {
        switch role {
        case "admin":        return "Admin"
        case "super_admin":  return "Super Admin"
        case "professional": return "Profesional"
        default:             return "Usuario"
        }
    }

    private func roleColor(_ role: String) -> Color {
        switch role {
        case "admin", "super_admin": return Color.maresmeError
        case "professional":         return Color.maresmeSea
        default:                     return Color.maresmeBlue
        }
    }
}

// MARK: - Mi perfil detalle

private struct UserProfileDetailView: View {
    let user: UserModel

    var body: some View {
        List {
            Section("Datos personales") {
                LabeledContent("Nombre",   value: user.name)
                LabeledContent("Email",    value: user.email)
                if let phone = user.phone {
                    LabeledContent("Teléfono", value: phone)
                }
                if let bio = user.bio, !bio.isEmpty {
                    LabeledContent("Bio", value: bio)
                }
            }

            Section("Cuenta") {
                LabeledContent("Rol", value: roleLabel(user.role))
                if let date = user.createdAt {
                    LabeledContent("Miembro desde", value: date.formatted(date: .abbreviated, time: .omitted))
                }
                LabeledContent("Verificado", value: user.emailVerified ? "Sí" : "Pendiente")
            }
        }
        .navigationTitle("Mi perfil")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
    }

    private func roleLabel(_ role: String) -> String {
        switch role {
        case "admin":        return "Administrador"
        case "super_admin":  return "Super Admin"
        case "professional": return "Profesional"
        default:             return "Usuario"
        }
    }
}

// MARK: - Notificaciones ajustes

private struct NotificationSettingsView: View {
    @Environment(PushNotificationManager.self) private var pushManager
    @Environment(\.openURL)                    private var openURL

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(pushManager.isAuthorized
                                  ? Color.maresmeSuccess.opacity(0.12)
                                  : Color.maresmeWarning.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: pushManager.statusIcon)
                            .font(.system(size: 20))
                            .foregroundStyle(pushManager.isAuthorized
                                             ? Color.maresmeSuccess
                                             : Color.maresmeWarning)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Notificaciones push")
                            .font(.maresmeLabel)
                            .foregroundStyle(Color.maresmeText)
                        Text(pushManager.isAuthorized
                             ? "Activadas — recibirás alertas y recomendaciones."
                             : "Desactivadas — actívalas para no perder propiedades.")
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeSubtext)
                    }
                }
                .padding(.vertical, 4)
            }

            if !pushManager.isAuthorized {
                Section {
                    if pushManager.authorizationStatus == .denied {
                        Button {
                            if let url = URL(string: "app-settings:") { openURL(url) }
                        } label: {
                            Label("Abrir Ajustes del sistema", systemImage: "gear")
                        }
                    } else {
                        Button {
                            Task { await pushManager.requestPermissions() }
                        } label: {
                            Label("Activar notificaciones", systemImage: "bell.badge")
                        }
                    }
                } footer: {
                    Text("Se abrirán los Ajustes del sistema para gestionar los permisos de la app.")
                        .font(.maresmeCaption)
                }
            }
        }
        .navigationTitle("Notificaciones")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .task { await pushManager.refreshStatus() }
    }
}

// MARK: - Sesiones (placeholder)

private struct SessionsPlaceholderView: View {
    var body: some View {
        EmptyStateView(
            icon:    "iphone",
            title:   "Sesiones activas",
            message: "Próximamente podrás ver y cerrar sesiones remotas desde aquí."
        )
        .navigationTitle("Sesiones activas")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environment(SessionManager())
        .environment(PushNotificationManager.shared)
}
