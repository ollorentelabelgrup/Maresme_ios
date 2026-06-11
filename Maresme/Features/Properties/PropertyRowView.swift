import SwiftUI

struct PropertyRowView: View {
    let property: PropertyCard
    @Environment(FavoriteStore.self) private var favoriteStore

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            info
            Spacer(minLength: 0)
            favoriteButton
        }
        .padding(12)
        .background(Color.maresmeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Thumbnail

    private var thumbnail: some View {
        Group {
            if let url = property.mainImage.flatMap(URL.init) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholderImage
                    default:
                        Color.maresmeBackground
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(width: 100, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var placeholderImage: some View {
        ZStack {
            Color.maresmeBackground
            Image(systemName: "photo")
                .foregroundStyle(Color.maresmeDisabled)
        }
    }

    // MARK: - Info

    private var info: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(property.title)
                .font(.maresmeBody)
                .foregroundStyle(Color.maresmeText)
                .lineLimit(2)

            if let municipality = property.municipality {
                Label(municipality.name, systemImage: "mappin.circle")
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeSubtext)
            }

            HStack(spacing: 8) {
                if let rooms = property.rooms {
                    iconBadge(icon: "bed.double", value: "\(rooms)")
                }
                if let baths = property.bathrooms {
                    iconBadge(icon: "shower", value: "\(baths)")
                }
                if let surface = property.surfaceM2 {
                    iconBadge(icon: "square.dashed", value: "\(surface) m²")
                }
            }

            if let price = property.priceFormatted {
                Text(price)
                    .font(.maresmeLabel)
                    .foregroundStyle(Color.maresmeBlue)
            }
        }
    }

    private func iconBadge(icon: String, value: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(value)
                .font(.maresmeCaption)
        }
        .foregroundStyle(Color.maresmeSubtext)
    }

    // MARK: - Favorite button

    private var isFavorite: Bool {
        favoriteStore.isFavorite(property.slug, fallback: property.isFavorite)
    }

    private var favoriteButton: some View {
        Button {
            Task {
                await favoriteStore.toggle(
                    slug: property.slug,
                    currentFavorite: isFavorite
                )
            }
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 20))
                .foregroundStyle(isFavorite ? Color.maresmeError : Color.maresmeDisabled)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.borderless)    // prevents NavigationLink from capturing the tap
    }
}

#Preview {
    PropertyRowView(property: PreviewData.propertyCard)
        .padding()
        .background(Color.maresmeBackground)
        .environment(FavoriteStore())
}
