import UIKit

// DeviceService prepares the skeleton for APNs push token registration (MB-7).
// In MB-6 it handles device_uuid generation and registration call post-login.
struct DeviceRegistrationRequest: Encodable {
    let token:      String
    let platform:   String
    let deviceName: String?
    let deviceUuid: String?

    enum CodingKeys: String, CodingKey {
        case token, platform
        case deviceName = "device_name"
        case deviceUuid = "device_uuid"
    }
}

enum DeviceService {
    // Stable identifier for this device install (nil if unavailable).
    static var deviceUuid: String? {
        UIDevice.current.identifierForVendor?.uuidString
    }

    // Called post-login when an APNs push token is available.
    // In MB-6 this is a no-op (no APNs permission requested yet).
    // In MB-7 this will be called from didRegisterForRemoteNotificationsWithDeviceToken.
    static func registerIfNeeded(pushToken: String?, client: APIClient) async {
        guard let pushToken else { return }
        let body = DeviceRegistrationRequest(
            token:      pushToken,
            platform:   "ios",
            deviceName: UIDevice.current.name,
            deviceUuid: deviceUuid
        )
        do {
            try await client.requestVoid(Endpoint(.post, "/devices", body: body))
        } catch {
            // Non-blocking: failure logged, retry on next launch
            print("[DeviceService] registration failed: \(error)")
        }
    }
}
