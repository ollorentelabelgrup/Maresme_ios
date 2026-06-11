import Foundation

enum Config {
    // DEBUG → servidor local Herd (maresme.test)
    // RELEASE → producción (maresme.es)
    #if DEBUG
    static let apiBaseURL = URL(string: "https://maresme.test/api/v1")!
    #else
    static let apiBaseURL = URL(string: "https://maresme.es/api/v1")!
    #endif
    static let apiVersion = "v1"

    enum API {
        static let requestTimeout:  TimeInterval = 30
        static let resourceTimeout: TimeInterval = 60
    }

    enum Keychain {
        static let service      = "es.maresme.app"
        static let tokenAccount = "sanctum_token"
    }
}
