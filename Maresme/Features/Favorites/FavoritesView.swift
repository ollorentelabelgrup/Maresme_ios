import SwiftUI

struct FavoritesView: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                icon:    "heart.slash",
                title:   "Sin favoritos",
                message: "Guarda propiedades para verlas aquí. Disponible en MB-7."
            )
            .navigationTitle("Favoritos")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.maresmeBackground)
        }
    }
}

#Preview { FavoritesView() }
