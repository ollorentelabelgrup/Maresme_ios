import SwiftUI

struct SearchView: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                icon:    "magnifyingglass",
                title:   "Búsqueda",
                message: "Próximamente en MB-7: filtros avanzados, mapa y resultados en tiempo real."
            )
            .navigationTitle("Buscar")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.maresmeBackground)
        }
    }
}

#Preview { SearchView() }
