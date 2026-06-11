import SwiftUI
import Observation

@Observable
final class AuthViewModel {
    var email    = ""
    var password = ""
    var name     = ""
    var passwordConfirmation = ""

    var isLoading = false
    var errorMessage: String?
    var fieldErrors: [String: [String]] = [:]

    private let authService: AuthService
    private let session:     SessionManager

    init(session: SessionManager, authService: AuthService = AuthService()) {
        self.session     = session
        self.authService = authService
    }

    func login() async {
        guard validate(mode: .login) else { return }
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await authService.login(email: email, password: password)
            session.signIn(token: response.accessToken, user: response.user)
            if let me = try? await authService.me() {
                session.restoreSession(from: me)
            }
        } catch let error as APIError {
            handleError(error)
        } catch {
            errorMessage = "Error inesperado. Inténtalo de nuevo."
        }
    }

    func register() async {
        guard validate(mode: .register) else { return }
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await authService.register(
                name:         name,
                email:        email,
                password:     password,
                confirmation: passwordConfirmation
            )
            session.signIn(token: response.accessToken, user: response.user)
            if let me = try? await authService.me() {
                session.restoreSession(from: me)
            }
        } catch let error as APIError {
            handleError(error)
        } catch {
            errorMessage = "Error inesperado. Inténtalo de nuevo."
        }
    }

    // MARK: - Private

    private enum Mode { case login, register }

    private func validate(mode: Mode) -> Bool {
        errorMessage = nil
        fieldErrors  = [:]

        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            fieldErrors["email"] = ["El email es obligatorio."]
        }
        if password.isEmpty {
            fieldErrors["password"] = ["La contraseña es obligatoria."]
        }
        if mode == .register {
            if name.trimmingCharacters(in: .whitespaces).isEmpty {
                fieldErrors["name"] = ["El nombre es obligatorio."]
            }
            if password != passwordConfirmation {
                fieldErrors["password_confirmation"] = ["Las contraseñas no coinciden."]
            }
        }
        return fieldErrors.isEmpty
    }

    private func handleError(_ error: APIError) {
        switch error {
        case .validation(let message, let errors):
            errorMessage = message
            fieldErrors  = errors
        case .unauthorized:
            errorMessage = "Credenciales incorrectas."
        default:
            errorMessage = error.localizedDescription
        }
    }
}
