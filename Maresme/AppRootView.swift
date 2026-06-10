import SwiftUI

struct AppRootView: View {
    @Environment(SessionManager.self) private var session

    var body: some View {
        if session.isAuthenticated {
            MainTabView()
                .task { await resolveSession() }
        } else {
            LoginView()
        }
    }

    private func resolveSession() async {
        guard session.currentUser == nil else { return }
        do {
            let user = try await AuthService().me()
            session.restoreSession(user: user)
        } catch {
            // Token expired or invalid — force logout
            if let apiError = error as? APIError, apiError.isUnauthorized {
                session.signOut()
            }
        }
    }
}

// MARK: - Tab shell

private struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Inicio",    systemImage: "house") }
            SearchView()
                .tabItem { Label("Buscar",    systemImage: "magnifyingglass") }
            FavoritesView()
                .tabItem { Label("Favoritos", systemImage: "heart") }
            AlertsView()
                .tabItem { Label("Alertas",   systemImage: "bell") }
            ProfileView()
                .tabItem { Label("Perfil",    systemImage: "person") }
        }
        .tint(Color.maresmeBlue)
    }
}

#Preview {
    AppRootView()
        .environment(SessionManager())
}
