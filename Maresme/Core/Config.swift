import Foundation

enum Config {
    // DEBUG → IP LAN del Mac (simulador + dispositivo físico en la misma red WiFi).
    //         El simulador iOS 14+ no resuelve /etc/hosts, así que se usa la IP directa.
    //         ServBay sirve en esta IP con cert para maresme.test — APIClient bypasea
    //         el mismatch de cert solo en DEBUG (ver DebugSSLDelegate).
    //         Actualizar si cambia la IP del Mac: ipconfig getifaddr en0
    // RELEASE → producción (maresme.es)
    #if DEBUG
    static let apiBaseURL    = URL(string: "https://192.168.1.40/api/v1")!
    static let apiDevHostname = "maresme.test"   // hostname real del cert ServBay
    #else
    static let apiBaseURL    = URL(string: "https://maresme.es/api/v1")!
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
