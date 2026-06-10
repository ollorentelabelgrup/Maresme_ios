import SwiftUI

// HomeView MB-6: minimal — shows authenticated user info and session state.
// Full favorites/alerts/recommendations calls are planned for MB-7+.
struct HomeView: View {
    @Environment(SessionManager.self) private var session

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    welcomeSection
                    sessionSection
                    placeholderSections
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color.maresmeBackground)
            .navigationTitle("Inicio")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Sections

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
                Text("Bienvenido")
                    .font(.maresmeTitle2)
                    .foregroundStyle(Color.maresmeText)
            }
        }
    }

    private var sessionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sesión activa")
                .font(.maresmeLabel)
                .foregroundStyle(Color.maresmeSubtext)

            VStack(spacing: 0) {
                if let user = session.currentUser {
                    infoRow(label: "Nombre",      value: user.name)
                    Divider().padding(.leading, 16)
                    infoRow(label: "Email",       value: user.email)
                    Divider().padding(.leading, 16)
                    infoRow(label: "Rol",         value: user.role.capitalized)
                    Divider().padding(.leading, 16)
                    infoRow(label: "Verificado",  value: user.emailVerified ? "Sí" : "No")
                } else {
                    HStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("Verificando sesión...")
                            .font(.maresmeBodySm)
                            .foregroundStyle(Color.maresmeSubtext)
                    }
                    .padding(16)
                }
            }
            .background(Color.maresmeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var placeholderSections: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Próximamente")
                .font(.maresmeLabel)
                .foregroundStyle(Color.maresmeSubtext)

            HStack(spacing: 12) {
                comingSoonCard(icon: "heart", title: "Favoritos")
                comingSoonCard(icon: "bell",  title: "Alertas")
            }
            HStack(spacing: 12) {
                comingSoonCard(icon: "sparkles",       title: "Recomendaciones")
                comingSoonCard(icon: "house.and.flag", title: "Novedades")
            }
        }
    }

    // MARK: - Helpers

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.maresmeBodySm)
                .foregroundStyle(Color.maresmeSubtext)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.maresmeBody)
                .foregroundStyle(Color.maresmeText)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func comingSoonCard(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(Color.maresmeDisabled)
            Text(title)
                .font(.maresmeCaption)
                .foregroundStyle(Color.maresmeSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.maresmeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    let session = SessionManager()
    HomeView()
        .environment(session)
}
