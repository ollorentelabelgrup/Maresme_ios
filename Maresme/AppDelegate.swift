import UIKit

// MARK: - AppDelegate

/// Punto de entrada UIKit para callbacks del sistema que no tienen equivalente SwiftUI.
/// Conecta APNs con PushNotificationManager via el singleton compartido.
final class AppDelegate: NSObject, UIApplicationDelegate {

    // ─── APNs token ───────────────────────────────────────────────────────────

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { await PushNotificationManager.shared.handleDeviceToken(deviceToken) }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[APNs] Registration failed: \(error.localizedDescription)")
    }

    // ─── Background remote notifications ─────────────────────────────────────

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Notificación en background: marcar el deep link para cuando el usuario abra la app.
        Task { @MainActor in
            PushNotificationManager.shared.handleUserInfo(userInfo)
        }
        completionHandler(.newData)
    }
}
