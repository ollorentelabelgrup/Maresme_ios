import SwiftUI

@main
struct MaresmeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var session               = SessionManager()
    @State private var favoriteStore         = FavoriteStore()
    @State private var alertStore            = AlertStore()
    @State private var recommendationStore   = RecommendationStore()
    @State private var notificationStore     = NotificationStore()
    @State private var propertySearchStore   = PropertySearchStore()
    @State private var navigationCoordinator = NavigationCoordinator()

    // Singleton compartido con AppDelegate (no puede ser @State)
    private let pushManager = PushNotificationManager.shared

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(session)
                .environment(favoriteStore)
                .environment(alertStore)
                .environment(recommendationStore)
                .environment(notificationStore)
                .environment(propertySearchStore)
                .environment(pushManager)
                .environment(navigationCoordinator)
                .onAppear { pushManager.configure() }
        }
    }
}
