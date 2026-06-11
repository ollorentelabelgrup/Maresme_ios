import SwiftUI

// SearchView — tab de propiedades con filtros persistentes (PropertySearchStore global).
// El store global mantiene los filtros activos mientras el usuario navega a otras tabs.
struct SearchView: View {
    @Environment(PropertySearchStore.self) private var searchStore

    var body: some View {
        NavigationStack {
            PropertyListView()
                .navigationTitle("Propiedades")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SearchView()
        .environment(PropertySearchStore())
        .environment(FavoriteStore())
}
