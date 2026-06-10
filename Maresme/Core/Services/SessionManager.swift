import SwiftUI
import Observation

@Observable
final class SessionManager {
    // MARK: - State

    var currentUser: UserModel?
    var isAuthenticated = false
    var isLoading       = false

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
            // Keychain failure — log but don't crash
            print("[SessionManager] failed to save token: \(error)")
        }
    }

    func signOut() {
        try? KeychainService.deleteToken()
        currentUser     = nil
        isAuthenticated = false
    }

    func restoreSession(user: UserModel) {
        currentUser = user
    }

    func updateUser(_ user: UserModel) {
        currentUser = user
    }
}
