import SwiftUI

struct RecommendationDetailView: View {
    let recommendation: Recommendation
    @Environment(FavoriteStore.self) private var favoriteStore
    @State private var viewModel: RecommendationDetailViewModel?

    private var isFav: Bool {
        favoriteStore.isFavorite(
            recommendation.property.slug,
            fallback: recommendation.property.isFavorite
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                propertyHeader

                VStack(alignment: .leading, spacing: 24) {
                    if viewModel?.isLoading == true && viewModel?.detail == nil {
                        LoadingView(message: "Analizando compatibilidad...")
                            .frame(height: 160)
                    } else if let detail = viewModel?.detail {
                        matchingSection(detail.matching)
                        Divider()
                        propertyLinkCard
                    } else if let err = viewModel?.error {
                        Text(err)
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeError)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .background(Color.maresmeBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task {
            let vm = RecommendationDetailViewModel(slug: recommendation.property.slug)
            viewModel = vm
            await vm.load()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            MatchScoreBadge(
                score:   recommendation.score,
                quality: recommendation.quality,
                compact: true
            )
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Task {
                    await favoriteStore.toggle(
                        slug: recommendation.property.slug,
                        currentFavorite: isFav
                    )
                }
            } label: {
                Image(systemName: isFav ? "heart.fill" : "heart")
                    .foregroundStyle(Color.maresmeError)
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: - Property header

    private var propertyHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            heroImage
            VStack(alignment: .leading, spacing: 10) {
                Text(recommendation.property.title)
                    .font(.maresmeTitle3)
                    .foregroundStyle(Color.maresmeText)

                HStack(spacing: 16) {
                    if let price = recommendation.property.priceFormatted {
                        Text(price)
                            .font(.maresmeLabelLg)
                            .foregroundStyle(Color.maresmeBlue)
                    }
                    if let mun = recommendation.property.municipality {
                        Label(mun.name, systemImage: "mappin.circle")
                            .font(.maresmeBodySm)
                            .foregroundStyle(Color.maresmeSubtext)
                    }
                }

                HStack(spacing: 8) {
                    if let r = recommendation.property.rooms {
                        statChip("\(r) hab", "bed.double")
                    }
                    if let b = recommendation.property.bathrooms {
                        statChip("\(b) baños", "shower")
                    }
                    if let s = recommendation.property.surfaceM2 {
                        statChip("\(s) m²", "square")
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private var heroImage: some View {
        Group {
            if let url = recommendation.property.mainImage.flatMap(URL.init) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default:               Color.maresmeBackground
                    }
                }
            } else {
                ZStack {
                    Color.maresmeBackground
                    Image(systemName: "house")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.maresmeDisabled)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .clipped()
    }

    private func statChip(_ text: String, _ icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.maresmeCaption)
        }
        .foregroundStyle(Color.maresmeSubtext)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.maresmeBackground)
        .clipShape(Capsule())
    }

    // MARK: - Matching section

    private func matchingSection(_ info: RecommendationDetail.MatchingInfo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                MatchScoreBadge(score: info.score, quality: info.quality)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Compatibilidad con tu perfil")
                        .font(.maresmeLabel)
                        .foregroundStyle(Color.maresmeText)
                    if let reason = info.reason, !reason.isEmpty {
                        Text(reason)
                            .font(.maresmeBodySm)
                            .foregroundStyle(Color.maresmeSubtext)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            breakdownCard(info.breakdown)
        }
    }

    // MARK: - Breakdown bars

    private func breakdownCard(_ bd: RecommendationDetail.MatchingInfo.MatchBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Desglose de compatibilidad")
                .font(.maresmeLabel)
                .foregroundStyle(Color.maresmeSubtext)

            breakdownRow("Municipio",   "mappin.circle",   bd.municipality)
            breakdownRow("Presupuesto", "eurosign.circle", bd.budget)
            breakdownRow("Tipo",        "house",           bd.propertyType)
            breakdownRow("Afinidad",    "heart.circle",    bd.affinity)
        }
        .padding(14)
        .background(Color.maresmeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func breakdownRow(_ label: String, _ icon: String, _ score: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(barColor(score))
                .frame(width: 20)

            Text(label)
                .font(.maresmeBodySm)
                .foregroundStyle(Color.maresmeText)
                .frame(width: 90, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.maresmeBackground)
                        .frame(height: 8)
                    Capsule()
                        .fill(barColor(score))
                        .frame(width: geo.size.width * CGFloat(score) / 100, height: 8)
                        .animation(.easeOut(duration: 0.6), value: score)
                }
            }
            .frame(height: 8)

            Text("\(score)")
                .font(.maresmeLabel)
                .foregroundStyle(barColor(score))
                .frame(width: 28, alignment: .trailing)
        }
    }

    private func barColor(_ score: Int) -> Color {
        switch score {
        case 90...: return Color(red: 0.09, green: 0.64, blue: 0.27)
        case 80...: return Color.maresmeSuccess
        case 70...: return Color.maresmeBlue
        case 60...: return Color.maresmeWarning
        default:    return Color.maresmeDisabled
        }
    }

    // MARK: - Link a ficha completa

    private var propertyLinkCard: some View {
        NavigationLink(value: recommendation.property.slug) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ver ficha completa")
                        .font(.maresmeLabel)
                        .foregroundStyle(Color.maresmeBlue)
                    Text("Fotos, descripción, características, agencia")
                        .font(.maresmeCaption)
                        .foregroundStyle(Color.maresmeSubtext)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.maresmeBlue)
            }
            .padding(14)
            .background(Color.maresmeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        RecommendationDetailView(recommendation: PreviewData.recommendation)
            .environment(FavoriteStore())
            .navigationDestination(for: String.self) { slug in
                PropertyDetailView(slug: slug)
            }
    }
}
