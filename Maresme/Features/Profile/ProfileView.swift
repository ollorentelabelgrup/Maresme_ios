import SwiftUI

struct ProfileView: View {
    @Environment(SessionManager.self) private var session

    var body: some View {
        NavigationStack {
            List {
                if let user = session.currentUser {
                    Section("Cuenta") {
                        LabeledContent("Nombre",  value: user.name)
                        LabeledContent("Email",   value: user.email)
                        LabeledContent("Rol",     value: user.role.capitalized)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        session.signOut()
                    } label: {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ProfileView()
        .environment(SessionManager())
}
