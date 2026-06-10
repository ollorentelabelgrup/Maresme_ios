import SwiftUI

struct RegisterView: View {
    @Environment(SessionManager.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AuthViewModel?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerSection
                formSection
                actionSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 32)
        }
        .background(Color.maresmeBackground)
        .navigationTitle("Crear cuenta")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = AuthViewModel(session: session)
            }
        }
    }

    private var headerSection: some View {
        Text("Únete a la comunidad del Maresme")
            .font(.maresmeTitle3)
            .foregroundStyle(Color.maresmeText)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var formSection: some View {
        if let vm = viewModel {
            @Bindable var bound = vm
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Nombre", text: $bound.name)
                        .textContentType(.name)
                        .maresmeTextField()
                    fieldError(vm.fieldErrors["name"])
                }

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
                        .textContentType(.newPassword)
                        .maresmeTextField()
                    fieldError(vm.fieldErrors["password"])
                }

                VStack(alignment: .leading, spacing: 4) {
                    SecureField("Confirmar contraseña", text: $bound.passwordConfirmation)
                        .textContentType(.newPassword)
                        .maresmeTextField()
                    fieldError(vm.fieldErrors["password_confirmation"])
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
                PrimaryButton("Crear cuenta", isLoading: vm.isLoading) {
                    Task { await vm.register() }
                }

                Button("Ya tengo cuenta") { dismiss() }
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
    NavigationStack {
        RegisterView()
            .environment(SessionManager())
    }
}
