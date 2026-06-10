import Foundation

enum Config {
    static let apiBaseURL = URL(string: "https://maresme.es/api/v1")!
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
