import SwiftUI

struct AppRootView: View {
    @Environment(SessionManager.self)          private var session
    @Environment(FavoriteStore.self)           private var favoriteStore
    @Environment(AlertStore.self)             private var alertStore
    @Environment(RecommendationStore.self)    private var recommendationStore
    @Environment(NotificationStore.self)      private var notificationStore
    @Environment(PushNotificationManager.self) private var pushManager
    @Environment(NavigationCoordinator.self)   private var coordinator

    @State private var splashVisible = true

    var body: some View {
        ZStack {
            Group {
                if session.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                        .onAppear { resetStores() }
                }
            }

            if splashVisible {
                SplashView()
                    .zIndex(1)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.35), value: splashVisible)
        .task { await boot() }
        .onChange(of: pushManager.pendingDeepLink) { _, deepLink in
            if let deepLink {
                coordinator.navigate(to: deepLink)
                pushManager.pendingDeepLink = nil
            }
        }
    }

    // MARK: - Boot sequence
    // Muestra SplashView mínimo 1.2s y en paralelo restaura la sesión.
    // La splash se oculta cuando ambas tareas completan.

    private func boot() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                try? await Task.sleep(for: .seconds(1.2))
            }
            group.addTask {
                await pushManager.requestPermissions()
                guard session.isAuthenticated else { return }
                guard session.currentUser == nil else {
                    if let deepLink = pushManager.pendingDeepLink {
                        coordinator.navigate(to: deepLink)
                        pushManager.pendingDeepLink = nil
                    }
                    return
                }
                do {
                    let meResponse = try await AuthService().me()
                    session.restoreSession(from: meResponse)
                    await favoriteStore.loadCount()
                    await alertStore.load()
                    await recommendationStore.loadCount()
                    await notificationStore.loadCount()
                    if let deepLink = pushManager.pendingDeepLink {
                        coordinator.navigate(to: deepLink)
                        pushManager.pendingDeepLink = nil
                    }
                } catch {
                    if let apiError = error as? APIError, apiError.isUnauthorized {
                        session.signOut()
                    }
                }
            }
            await group.waitForAll()
        }
        withAnimation(.easeOut(duration: 0.35)) {
            splashVisible = false
        }
    }

    private func resetStores() {
        favoriteStore.reset()
        alertStore.reset()
        recommendationStore.reset()
        notificationStore.reset()
    }
}

// MARK: - Tab shell

private struct MainTabView: View {
    @Environment(FavoriteStore.self)          private var favoriteStore
    @Environment(AlertStore.self)             private var alertStore
    @Environment(NotificationStore.self)      private var notificationStore
    @Environment(NavigationCoordinator.self)  private var coordinator

    var body: some View {
        @Bindable var coord = coordinator
        TabView(selection: $coord.selectedTab) {
            HomeView()
                .tabItem { Label("Inicio",      systemImage: "house") }
                .tag(0)
            SearchView()
                .tabItem { Label("Propiedades", systemImage: "magnifyingglass") }
                .tag(1)
            FavoritesView()
                .tabItem { Label("Favoritos",   systemImage: "heart") }
                .badge(favoriteStore.count > 0 ? favoriteStore.count : 0)
                .tag(2)
            AlertsView()
                .tabItem { Label("Alertas",     systemImage: "bell") }
                .badge(alertStore.newMatchesCount > 0 ? alertStore.newMatchesCount : 0)
                .tag(3)
            NotificationsView()
                .tabItem { Label("Actividad",   systemImage: "bell.badge") }
                .badge(notificationStore.unreadCount > 0 ? notificationStore.unreadCount : 0)
                .tag(4)
        }
        .tint(Color.maresmeBlue)
    }
}

// MARK: - Preview

#Preview {
    AppRootView()
        .environment(SessionManager())
        .environment(FavoriteStore())
        .environment(AlertStore())
        .environment(RecommendationStore())
        .environment(NotificationStore())
        .environment(PropertySearchStore())
        .environment(PushNotificationManager.shared)
        .environment(NavigationCoordinator())
}
