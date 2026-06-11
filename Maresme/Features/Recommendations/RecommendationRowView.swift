import SwiftUI

struct RecommendationRowView: View {
    let recommendation: Recommendation
    @Environment(FavoriteStore.self) private var favoriteStore

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            infoColumn
            MatchScoreBadge(
                score:   recommendation.score,
                quality: recommendation.quality,
                compact: true
            )
        }
        .padding(12)
        .background(Color.maresmeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Thumbnail

    private var thumbnail: some View {
        ZStack(alignment: .topLeading) {
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
                            .foregroundStyle(Color.maresmeDisabled)
                    }
                }
            }
            .frame(width: 80, height: 80)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if recommendation.isNew {
                Text("Nueva")
                    .font(.maresmeLabelSm)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.maresmeBlue)
                    .clipShape(Capsule())
                    .padding(4)
            }
        }
    }

    // MARK: - Info

    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(recommendation.property.title)
                .font(.maresmeBodySm)
                .foregroundStyle(Color.maresmeText)
                .lineLimit(2)

            if let municipality = recommendation.property.municipality {
                Label(municipality.name, systemImage: "mappin.circle")
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeSubtext)
            }

            if let price = recommendation.property.priceFormatted {
                Text(price)
                    .font(.maresmeLabel)
                    .foregroundStyle(Color.maresmeBlue)
            }

            if let reason = recommendation.reason, !reason.isEmpty {
                Text(reason)
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeSubtext)
                    .lineLimit(1)
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    RecommendationRowView(recommendation: PreviewData.recommendation)
        .environment(FavoriteStore())
        .padding()
        .background(Color.maresmeBackground)
}
