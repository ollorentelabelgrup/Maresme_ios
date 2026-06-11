import SwiftUI

struct FavoritesView: View {
    @Environment(FavoriteStore.self) private var favoriteStore
    @State private var viewModel = FavoritesViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.favorites.isEmpty {
                    LoadingView(message: "Cargando favoritos...")
                } else if let error = viewModel.errorMessage, viewModel.favorites.isEmpty {
                    EmptyStateView(
                        icon:        "exclamationmark.triangle",
                        title:       "Error al cargar",
                        message:     error,
                        action:      { Task { await viewModel.loadInitial() } },
                        actionTitle: "Reintentar"
                    )
                } else if viewModel.favorites.isEmpty {
                    EmptyStateView(
                        icon:    "heart.slash",
                        title:   "Sin favoritos",
                        message: "Guarda propiedades tocando el corazón para verlas aquí."
                    )
                } else {
                    favoritesList
                }
            }
            .navigationTitle("Favoritos")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.maresmeBackground)
        }
        .task {
            await viewModel.loadInitial()
            favoriteStore.seedFromFavorites(viewModel.loadedSlugs)
        }
    }

    // MARK: - List

    private var favoritesList: some View {
        List {
            ForEach(viewModel.favorites) { favorite in
                NavigationLink(value: favorite.property.slug) {
                    PropertyRowView(property: favorite.property)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.maresmeBackground)
                .listRowSeparator(.hidden)
                .onAppear {
                    if favorite.id == viewModel.favorites.last?.id {
                        Task {
                            await viewModel.loadMore()
                            favoriteStore.seedFromFavorites(viewModel.loadedSlugs)
                        }
                    }
                }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.maresmeBackground)
                .listRowSeparator(.hidden)
                .padding(.vertical, 8)
            }
        }
        .listStyle(.plain)
        .background(Color.maresmeBackground)
        .refreshable {
            await viewModel.refresh()
            favoriteStore.seedFromFavorites(viewModel.loadedSlugs)
        }
        .navigationDestination(for: String.self) { slug in
            PropertyDetailView(slug: slug)
        }
    }
}

#Preview {
    FavoritesView()
        .environment(FavoriteStore())
}
