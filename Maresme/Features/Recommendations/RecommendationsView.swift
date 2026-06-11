import SwiftUI

struct RecommendationsView: View {
    @Environment(RecommendationStore.self) private var store
    @Environment(FavoriteStore.self)       private var favoriteStore
    @State private var viewModel: RecommendationsViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel?.isLoading == true && viewModel?.items.isEmpty == true {
                    LoadingView(message: "Cargando recomendaciones...")
                } else if let error = viewModel?.errorMessage, viewModel?.items.isEmpty == true {
                    EmptyStateView(
                        icon:        "exclamationmark.triangle",
                        title:       "Error al cargar",
                        message:     error,
                        action:      { Task { await viewModel?.load() } },
                        actionTitle: "Reintentar"
                    )
                } else if viewModel?.items.isEmpty == true {
                    emptyState
                } else {
                    itemList
                }
            }
            .navigationTitle("Para ti")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.maresmeBackground)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel?.refresh() }
                    } label: {
                        if viewModel?.isRefreshing == true {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(viewModel?.isRefreshing == true)
                }
            }
            .navigationDestination(for: Recommendation.self) { rec in
                RecommendationDetailView(recommendation: rec)
            }
            .navigationDestination(for: String.self) { slug in
                PropertyDetailView(slug: slug)
            }
        }
        .task {
            let vm = RecommendationsViewModel(store: store)
            viewModel = vm
            await vm.loadIfNeeded()
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        EmptyStateView(
            icon:        "sparkles",
            title:       "Sin recomendaciones aún",
            message:     "Generamos recomendaciones personalizadas en función de tu perfil y actividad en la plataforma.",
            action:      { Task { await viewModel?.refresh() } },
            actionTitle: "Generar ahora"
        )
    }

    // MARK: - List

    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                refreshBanner

                ForEach(viewModel?.items ?? []) { rec in
                    NavigationLink(value: rec) {
                        RecommendationRowView(recommendation: rec)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if rec.id == viewModel?.items.last?.id {
                            Task { await viewModel?.loadMore() }
                        }
                    }
                }

                if viewModel?.isLoadingMore == true {
                    ProgressView().padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .refreshable { await viewModel?.load() }
    }

    @ViewBuilder
    private var refreshBanner: some View {
        if let message = viewModel?.refreshMessage {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                Text(message)
                    .font(.maresmeCaption)
            }
            .foregroundStyle(Color.maresmeBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.maresmeBlue.opacity(0.08))
            .clipShape(Capsule())
            .padding(.top, 4)
        }
    }
}

#Preview {
    RecommendationsView()
        .environment(RecommendationStore())
        .environment(FavoriteStore())
}
