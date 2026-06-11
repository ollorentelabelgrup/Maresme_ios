import SwiftUI
import Observation

@Observable
final class SessionManager {
    // MARK: - State

    var currentUser:    UserModel?
    var currentAgency:  AgencyModel?
    var isAuthenticated = false
    var isLoading       = false

    // El usuario es "profesional" si tiene membresía activa en una agencia.
    var isProfessionalUser: Bool { currentAgency != nil }

    // MARK: - Init

    init() {
        isAuthenticated = KeychainService.hasToken()
    }

    // MARK: - Actions

    func signIn(token: String, user: UserModel) {
        do {
            try KeychainService.saveToken(token)
            currentUser     = user
            isAuthenticated = true
        } catch {
            print("[SessionManager] failed to save token: \(error)")
        }
    }

    func signOut() {
        try? KeychainService.deleteToken()
        currentUser     = nil
        currentAgency   = nil
        isAuthenticated = false
    }

    // Restaura sesión con la respuesta completa de /me (user + agency).
    func restoreSession(from response: MeResponse) {
        currentUser   = response.user
        currentAgency = response.agency
    }

    func updateUser(_ user: UserModel) {
        currentUser = user
    }
}
