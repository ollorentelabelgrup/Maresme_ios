import SwiftUI

struct PropertyDetailView: View {
    let slug: String
    @State private var viewModel: PropertyDetailViewModel
    @State private var selectedPhotoIndex = 0
    @Environment(FavoriteStore.self) private var favoriteStore

    init(slug: String) {
        self.slug  = slug
        _viewModel = State(initialValue: PropertyDetailViewModel(slug: slug))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Cargando propiedad...")
            } else if let error = viewModel.errorMessage {
                EmptyStateView(
                    icon:        "exclamationmark.triangle",
                    title:       "No se pudo cargar",
                    message:     error,
                    action:      { Task { await viewModel.reload() } },
                    actionTitle: "Reintentar"
                )
            } else if let property = viewModel.property {
                detail(property)
            }
        }
        .task { await viewModel.load() }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.maresmeBackground)
    }

    // MARK: - Detail layout

    @ViewBuilder
    private func detail(_ p: PropertyDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroImage(p)
                VStack(alignment: .leading, spacing: 20) {
                    headerSection(p)
                    Divider()
                    statsSection(p)
                    if let desc = p.description, !desc.isEmpty {
                        Divider()
                        descriptionSection(desc)
                    }
                    if hasAmenities(p) {
                        Divider()
                        amenitiesSection(p)
                    }
                    if !p.photos.dropFirst().isEmpty {
                        Divider()
                        gallerySection(p.photos)
                    }
                    if let agency = p.agency {
                        Divider()
                        agencySection(agency)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                let isFav = favoriteStore.isFavorite(p.slug, fallback: p.isFavorite)
                Button {
                    Task {
                        await favoriteStore.toggle(
                            slug: p.slug,
                            currentFavorite: isFav
                        )
                    }
                } label: {
                    Image(systemName: isFav ? "heart.fill" : "heart")
                        .foregroundStyle(isFav ? Color.maresmeError : Color.primary)
                }

                if let shareUrl = p.shareUrl, let url = URL(string: shareUrl) {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    // MARK: - Hero image (swipeable when photos available)

    @ViewBuilder
    private func heroImage(_ p: PropertyDetail) -> some View {
        ZStack(alignment: .bottomLeading) {
            if !p.photos.isEmpty {
                TabView(selection: $selectedPhotoIndex) {
                    ForEach(p.photos.indices, id: \.self) { i in
                        if let url = URL(string: p.photos[i]) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img): img.resizable().scaledToFill()
                                default: Color.maresmeBackground
                                }
                            }
                            .tag(i)
                        } else {
                            Color.maresmeBackground.tag(i)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .clipped()
            } else {
                let imageUrl = (p.heroImage ?? p.mainImage).flatMap(URL.init)
                Group {
                    if let url = imageUrl {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFill()
                            default: Color.maresmeBackground
                            }
                        }
                    } else {
                        ZStack {
                            Color.maresmeBackground
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.maresmeDisabled)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .clipped()
            }

            if p.photos.count > 1 {
                Text("\(selectedPhotoIndex + 1) / \(p.photos.count)")
                    .font(.maresmeLabelSm)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.55))
                    .clipShape(Capsule())
                    .padding(12)
            }
        }
    }

    // MARK: - Header

    private func headerSection(_ p: PropertyDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if p.isFeatured  { propertyTag("Destacado",  color: .maresmeGold) }
                if p.isNewBuild  { propertyTag("Obra nueva", color: .maresmeSea) }
                if p.isExclusive { propertyTag("Exclusiva",  color: .maresmeBlue) }
                Spacer()
            }

            Text(p.title)
                .font(.maresmeTitle2)
                .foregroundStyle(Color.maresmeText)

            if let municipality = p.municipality {
                Label(municipality.name, systemImage: "mappin.circle.fill")
                    .font(.maresmeBody)
                    .foregroundStyle(Color.maresmeSubtext)
            }

            if let price = p.priceFormatted {
                Text(price)
                    .font(.maresmeTitle3)
                    .foregroundStyle(Color.maresmeBlue)
            }

            if let ref = p.referenceCode {
                Text("Ref: \(ref)")
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeDisabled)
            }
        }
    }

    // MARK: - Stats

    private func statsSection(_ p: PropertyDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Características")
                .font(.maresmeLabel)
                .foregroundStyle(Color.maresmeSubtext)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let rooms = p.rooms {
                    statCell(icon: "bed.double",    label: "Habitaciones", value: "\(rooms)")
                }
                if let baths = p.bathrooms {
                    statCell(icon: "shower",         label: "Baños",        value: "\(baths)")
                }
                if let surface = p.surfaceM2 {
                    statCell(icon: "square.dashed",  label: "Superficie",   value: "\(surface) m²")
                }
                if let useful = p.usefulSurfaceM2 {
                    statCell(icon: "ruler",          label: "Útil",         value: "\(useful) m²")
                }
                if let floor = p.floorNumber {
                    statCell(icon: "building.2",     label: "Planta",       value: "\(floor)ª")
                }
                if let year = p.yearBuilt {
                    statCell(icon: "calendar",       label: "Año",          value: "\(year)")
                }
            }
        }
    }

    private func statCell(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.maresmeBlue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeSubtext)
                Text(value)
                    .font(.maresmeBody)
                    .foregroundStyle(Color.maresmeText)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.maresmeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func propertyTag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.maresmeLabelSm)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }

    // MARK: - Description

    private func descriptionSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Descripción")
                .font(.maresmeLabel)
                .foregroundStyle(Color.maresmeSubtext)
            Text(text)
                .font(.maresmeBody)
                .foregroundStyle(Color.maresmeText)
        }
    }

    // MARK: - Amenities

    private func hasAmenities(_ p: PropertyDetail) -> Bool {
        p.hasPool || p.hasGarden || p.hasParking || p.hasSeaView
        || p.hasElevator || p.hasTerrace || p.hasStorageRoom
    }

    private func amenitiesSection(_ p: PropertyDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extras")
                .font(.maresmeLabel)
                .foregroundStyle(Color.maresmeSubtext)

            let items: [(Bool, String, String)] = [
                (p.hasPool,        "drop.fill",       "Piscina"),
                (p.hasGarden,      "leaf.fill",       "Jardín"),
                (p.hasParking,     "car.fill",        "Parking"),
                (p.hasSeaView,     "water.waves",     "Vistas al mar"),
                (p.hasElevator,    "arrow.up.arrow.down", "Ascensor"),
                (p.hasTerrace,     "door.sliding.right.hand.open", "Terraza"),
                (p.hasStorageRoom, "archivebox.fill", "Trastero"),
            ]

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(items.filter { $0.0 }, id: \.2) { _, icon, label in
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.maresmeBlue)
                        Text(label)
                            .font(.maresmeBodySm)
                            .foregroundStyle(Color.maresmeText)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.maresmeSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    // MARK: - Gallery

    private func gallerySection(_ photos: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Galería (\(photos.count) fotos)")
                .font(.maresmeLabel)
                .foregroundStyle(Color.maresmeSubtext)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(photos.indices, id: \.self) { i in
                        if let url = URL(string: photos[i]) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img): img.resizable().scaledToFill()
                                default: Color.maresmeBackground
                                }
                            }
                            .frame(width: 200, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Agency

    private func agencySection(_ agency: PropertyDetail.AgencyRef) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Agencia")
                .font(.maresmeLabel)
                .foregroundStyle(Color.maresmeSubtext)

            HStack(spacing: 12) {
                if let logoUrl = agency.logoUrl.flatMap(URL.init) {
                    AsyncImage(url: logoUrl) { phase in
                        if case .success(let img) = phase { img.resizable().scaledToFit() }
                        else { Color.maresmeBackground }
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    ZStack {
                        Color.maresmeBackground
                        Image(systemName: "building.2")
                            .foregroundStyle(Color.maresmeSubtext)
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(agency.name)
                        .font(.maresmeBody)
                        .foregroundStyle(Color.maresmeText)
                    if let phone = agency.phone {
                        Text(phone)
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeSubtext)
                    }
                }
                Spacer()
            }
            .padding(12)
            .background(Color.maresmeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    NavigationStack {
        PropertyDetailView(slug: "piso-alella-3hab-luminoso")
    }
}
