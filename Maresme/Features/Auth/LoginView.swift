import SwiftUI

struct LoginView: View {
    @Environment(SessionManager.self) private var session
    @State private var viewModel: AuthViewModel?
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    formSection
                    actionSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 48)
                .padding(.bottom, 32)
            }
            .background(Color.maresmeBackground)
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AuthViewModel(session: session)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Maresme")
                .font(.maresmeTitle1)
                .foregroundStyle(Color.maresmeBlue)

            Text("Encuentra tu hogar en el Maresme")
                .font(.maresmeBody)
                .foregroundStyle(Color.maresmeSubtext)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var formSection: some View {
        if let vm = viewModel {
            @Bindable var bound = vm
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Email", text: $bound.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .maresmeTextField()
                    fieldError(vm.fieldErrors["email"])
                }

                VStack(alignment: .leading, spacing: 4) {
                    SecureField("Contraseña", text: $bound.password)
                        .textContentType(.password)
                        .maresmeTextField()
                    fieldError(vm.fieldErrors["password"])
                }

                if let message = vm.errorMessage {
                    Text(message)
                        .font(.maresmeCaption)
                        .foregroundStyle(Color.maresmeError)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        if let vm = viewModel {
            VStack(spacing: 16) {
                PrimaryButton("Iniciar sesión", isLoading: vm.isLoading) {
                    Task { await vm.login() }
                }

                Button("¿No tienes cuenta? Regístrate") {
                    showRegister = true
                }
                .font(.maresmeBodySm)
                .foregroundStyle(Color.maresmeBlue)
            }
        }
    }

    @ViewBuilder
    private func fieldError(_ errors: [String]?) -> some View {
        if let first = errors?.first {
            Text(first)
                .font(.maresmeCaption)
                .foregroundStyle(Color.maresmeError)
        }
    }
}

// MARK: - TextField style helper

private extension View {
    func maresmeTextField() -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.maresmeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.maresmeDisabled, lineWidth: 1)
            )
    }
}

#Preview {
    LoginView()
        .environment(SessionManager())
}
