import SwiftUI

struct AlertsView: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                icon:    "bell.slash",
                title:   "Sin alertas",
                message: "Crea alertas para recibir notificaciones de nuevas propiedades. Disponible en MB-7."
            )
            .navigationTitle("Alertas")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.maresmeBackground)
        }
    }
}

#Preview { AlertsView() }
