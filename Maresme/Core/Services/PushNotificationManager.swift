import UIKit
import UserNotifications

// MARK: - PushNotificationManager

/// Gestiona permisos APNs, registro del device token y deep links de push notifications.
///
/// Ciclo de vida:
///   1. `configure()` — llamar una vez desde @MainActor (MaresmeApp.body .onAppear)
///   2. `requestPermissions()` — llamar post-login en resolveSession()
///   3. `handleDeviceToken(_:)` — llamado desde AppDelegate.didRegisterForRemoteNotifications
///   4. `pendingDeepLink` — observado por AppRootView para enrutar la navegación
@Observable
final class PushNotificationManager: NSObject {
    // Singleton accesible desde AppDelegate (no-@MainActor context)
    nonisolated(unsafe) static let shared = PushNotificationManager()

    var pushToken:           String?                = nil
    var authorizationStatus: UNAuthorizationStatus  = .notDetermined
    var pendingDeepLink:     PushDeepLink?          = nil

    // nonisolated para que el static let pueda inicializarlo fuera de @MainActor
    private nonisolated override init() {
        super.init()
    }

    // ─── Setup ────────────────────────────────────────────────────────────────

    /// Registra el delegate de UNUserNotificationCenter. Llamar desde .onAppear en MaresmeApp.
    func configure() {
        UNUserNotificationCenter.current().delegate = self
    }

    // ─── Permisos ─────────────────────────────────────────────────────────────

    /// Solicita permisos APNs y, si se conceden, registra el dispositivo con APNs.
    /// Llamar después del login exitoso (no en el arranque de la app).
    func requestPermissions() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            let settings = await center.notificationSettings()
            authorizationStatus = settings.authorizationStatus
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            print("[PushManager] Permission request failed: \(error)")
        }
    }

    /// Refresca el estado de autorización APNs desde Settings del sistema.
    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // ─── Device token ─────────────────────────────────────────────────────────

    /// Convierte el Data del token a hex string y lo registra en el backend.
    /// Llamado desde AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken.
    func handleDeviceToken(_ data: Data) async {
        let token = data.map { String(format: "%02x", $0) }.joined()
        pushToken = token
        await DeviceService.registerIfNeeded(pushToken: token, client: .shared)
    }

    // ─── Deep link ────────────────────────────────────────────────────────────

    /// Parsea el userInfo de un push y publica el deep link pendiente.
    func handleUserInfo(_ userInfo: [AnyHashable: Any]) {
        let actionType   = userInfo["action_type"] as? String
        let actionTarget = userInfo["action_target"] as? String
        pendingDeepLink  = PushDeepLink.from(actionType: actionType, target: actionTarget)
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    var statusLabel: String {
        switch authorizationStatus {
        case .authorized:    return "Activadas"
        case .provisional:   return "Provisionales"
        case .denied:        return "Desactivadas"
        case .notDetermined: return "No configuradas"
        case .ephemeral:     return "Temporales"
        @unknown default:    return "Desconocido"
        }
    }

    var statusIcon: String {
        isAuthorized ? "bell.badge.fill" : "bell.slash"
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationManager: UNUserNotificationCenterDelegate {

    /// App en primer plano: mostrar banner + badge + sonido.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    /// Tap sobre la notificación (app en background o cerrada).
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            PushNotificationManager.shared.handleUserInfo(userInfo)
        }
        completionHandler()
    }
}
