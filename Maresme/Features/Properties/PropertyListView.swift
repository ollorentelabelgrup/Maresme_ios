import SwiftUI

struct PropertyListView: View {
    @Environment(PropertySearchStore.self) private var searchStore
    @Environment(FavoriteStore.self)       private var favoriteStore
    @State private var viewModel   = PropertyListViewModel()
    @State private var showFilters = false

    var body: some View {
        VStack(spacing: 0) {
            if searchStore.hasActiveFilters {
                activeFiltersBar
                Divider()
            }
            contentArea
        }
        .background(Color.maresmeBackground)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                filtersButton
            }
        }
        .sheet(isPresented: $showFilters) {
            SearchFiltersView(currentFilters: searchStore.filters) { newFilters in
                searchStore.apply(newFilters)
            }
        }
        .task {
            await viewModel.loadInitial(filters: searchStore.filters)
        }
        .onChange(of: searchStore.filters) { _, newFilters in
            Task { await viewModel.loadInitial(filters: newFilters) }
        }
    }

    // MARK: - Chips de filtros activos

    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(searchStore.filters.activeChips) { chip in
                    chipView(chip)
                }
                Button {
                    searchStore.reset()
                } label: {
                    Text("Limpiar todo")
                        .font(.maresmeCaption)
                        .foregroundStyle(Color.maresmeError)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.maresmeError.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.maresmeBackground)
    }

    private func chipView(_ chip: PropertySearchFilters.Chip) -> some View {
        HStack(spacing: 4) {
            Text(chip.label)
                .font(.maresmeCaption)
            Button {
                searchStore.filters.remove(chipId: chip.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.maresmeBlue.opacity(0.10))
        .foregroundStyle(Color.maresmeBlue)
        .clipShape(Capsule())
    }

    // MARK: - Toolbar filters button

    private var filtersButton: some View {
        Button {
            showFilters = true
        } label: {
            if searchStore.activeCount > 0 {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.maresmeBlue)
                    Text("\(searchStore.activeCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 14, height: 14)
                        .background(Color.maresmeBlue)
                        .clipShape(Circle())
                        .offset(x: 7, y: -7)
                }
            } else {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 20))
            }
        }
    }

    // MARK: - Content area

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.isLoading && viewModel.properties.isEmpty {
            LoadingView()
        } else if let error = viewModel.errorMessage, viewModel.properties.isEmpty {
            EmptyStateView(
                icon:        "exclamationmark.triangle",
                title:       "Error al cargar",
                message:     error,
                action:      { Task { await viewModel.loadInitial(filters: searchStore.filters) } },
                actionTitle: "Reintentar"
            )
        } else if viewModel.properties.isEmpty && !viewModel.isLoading {
            EmptyStateView(
                icon:        "house.slash",
                title:       "Sin resultados",
                message:     searchStore.hasActiveFilters
                    ? "No hay propiedades con estos filtros. Prueba a ampliar la búsqueda."
                    : "No hay propiedades disponibles en este momento.",
                action:      searchStore.hasActiveFilters ? { searchStore.reset() } : nil,
                actionTitle: searchStore.hasActiveFilters ? "Limpiar filtros" : nil
            )
        } else {
            propertyList
        }
    }

    // MARK: - List

    private var propertyList: some View {
        List {
            ForEach(viewModel.properties) { property in
                NavigationLink(value: property.slug) {
                    PropertyRowView(property: property)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.maresmeBackground)
                .listRowSeparator(.hidden)
                .onAppear {
                    if property.id == viewModel.properties.last?.id {
                        Task { await viewModel.loadMore() }
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
        .refreshable { await viewModel.refresh() }
        .navigationDestination(for: String.self) { slug in
            PropertyDetailView(slug: slug)
        }
    }
}

#Preview {
    NavigationStack {
        PropertyListView()
            .navigationTitle("Propiedades")
            .navigationBarTitleDisplayMode(.large)
    }
    .environment(PropertySearchStore())
    .environment(FavoriteStore())
}

#Preview("Con filtros") {
    NavigationStack {
        PropertyListView()
            .navigationTitle("Propiedades")
            .navigationBarTitleDisplayMode(.large)
    }
    .environment(PropertySearchStore(initial: .init(type: "piso", priceMax: 450_000)))
    .environment(FavoriteStore())
}
