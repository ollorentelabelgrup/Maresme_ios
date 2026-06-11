import SwiftUI

struct AgencyPropertyDetailView: View {
    let slug: String

    @State private var vm: AgencyPropertyDetailViewModel
    @State private var actionToConfirm: AgencyPropertyDetail.PropertyAction? = nil

    init(slug: String) {
        self.slug = slug
        self._vm  = State(initialValue: AgencyPropertyDetailViewModel(slug: slug))
    }

    var body: some View {
        Group {
            if vm.isLoading {
                loadingView
            } else if let error = vm.errorMessage {
                errorView(error)
            } else if let property = vm.property {
                propertyContent(property)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let p = vm.property {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AgencyPropertyEditView(property: p) { updated in
                            vm.applyUpdate(updated)
                        }
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .task { await vm.load() }
        .refreshable { await vm.reload() }
        .alert("Error", isPresented: .constant(vm.actionError != nil)) {
            Button("Aceptar") { vm.actionError = nil }
        } message: {
            Text(vm.actionError ?? "")
        }
        .confirmationDialog(
            confirmationTitle,
            isPresented: .constant(actionToConfirm != nil),
            titleVisibility: .visible
        ) {
            if let action = actionToConfirm {
                Button(action.rawValue, role: action == .sell ? .destructive : .none) {
                    actionToConfirm = nil
                    Task { await vm.perform(action) }
                }
                Button("Cancelar", role: .cancel) { actionToConfirm = nil }
            }
        }
    }

    private var confirmationTitle: String {
        guard let action = actionToConfirm else { return "" }
        switch action {
        case .publish:    return "¿Publicar la propiedad?"
        case .unpublish:  return "¿Retirar la propiedad del mercado?"
        case .reserve:    return "¿Marcar como reservada?"
        case .reactivate: return "¿Reactivar la propiedad?"
        case .sell:       return "¿Marcar como vendida?"
        }
    }

    // MARK: - Main content

    private func propertyContent(_ p: AgencyPropertyDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroSection(p)
                VStack(alignment: .leading, spacing: 20) {
                    headerSection(p)
                    actionsSection(p)
                    keySpecsSection(p)
                    if let desc = p.description, !desc.isEmpty {
                        descriptionSection(desc)
                    }
                    photosManagementSection(p)
                    leadsSection(p)
                    metaSection(p)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Color.maresmeBackground)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Hero

    private func heroSection(_ p: AgencyPropertyDetail) -> some View {
        Group {
            if let urlString = p.heroImage, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                            .clipped()
                    default:
                        heroPlaceholder
                    }
                }
            } else {
                heroPlaceholder
            }
        }
    }

    private var heroPlaceholder: some View {
        ZStack {
            Color.maresmeBlue.opacity(0.08)
            Image(systemName: "house.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.maresmeBlue.opacity(0.25))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
    }

    // MARK: - Header

    private func headerSection(_ p: AgencyPropertyDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(p.title)
                        .font(.maresmeTitle3)
                        .foregroundStyle(Color.maresmeText)
                    if let municipality = p.municipality {
                        Label(municipality, systemImage: "mappin.circle.fill")
                            .font(.maresmeBodySm)
                            .foregroundStyle(Color.maresmeSubtext)
                    }
                }
                Spacer()
                statusBadgeView(p.statusDisplay)
            }

            if let price = p.priceFormatted {
                Text(price)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.maresmeBlue)
            }

            if let ref = p.referenceCode {
                Text("Ref. \(ref)")
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeSubtext)
            }
        }
    }

    // MARK: - Actions

    private func actionsSection(_ p: AgencyPropertyDetail) -> some View {
        let actions = p.availableActions
        guard !actions.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                Text("Acciones")
                    .font(.maresmeLabel)
                    .foregroundStyle(Color.maresmeText)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(actions, id: \.rawValue) { action in
                            actionButton(action)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.maresmeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                if vm.isPerformingAction {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.maresmeBackground.opacity(0.6))
                    ProgressView()
                }
            }
        )
    }

    private func actionButton(_ action: AgencyPropertyDetail.PropertyAction) -> some View {
        Button {
            actionToConfirm = action
        } label: {
            Label(action.rawValue, systemImage: action.icon)
                .font(.maresmeLabelSm)
                .foregroundStyle(Color.maresmeBlue)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.maresmeBlue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .disabled(vm.isPerformingAction)
    }

    // MARK: - Key specs

    private func keySpecsSection(_ p: AgencyPropertyDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Características")
                .font(.maresmeLabel)
                .foregroundStyle(Color.maresmeText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if let rooms = p.rooms {
                    specCell(value: "\(rooms)", label: "Habitaciones", icon: "bed.double")
                }
                if let baths = p.bathrooms {
                    specCell(value: "\(baths)", label: "Baños", icon: "shower")
                }
                if let surface = p.surfaceM2 {
                    specCell(value: "\(surface) m²", label: "Superficie", icon: "ruler")
                }
                if let useful = p.usefulSurfaceM2 {
                    specCell(value: "\(useful) m²", label: "Sup. útil", icon: "square.dashed")
                }
                specCell(value: p.typeLabel, label: "Tipo", icon: "tag")
                if let score = p.healthScore {
                    specCell(value: "\(score)%", label: "Calidad ficha", icon: "chart.bar.fill")
                }
                specCell(value: "\(p.leadsCount)", label: "Leads", icon: "person.badge.clock")
            }
        }
        .padding(16)
        .background(Color.maresmeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func specCell(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(Color.maresmeBlue)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.maresmeLabel)
                    .foregroundStyle(Color.maresmeText)
                Text(label)
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeSubtext)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.maresmeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Description

    private func descriptionSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Descripción")
                .font(.maresmeLabel)
                .foregroundStyle(Color.maresmeText)
            Text(text)
                .font(.maresmeBodySm)
                .foregroundStyle(Color.maresmeSubtext)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.maresmeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Photos management

    private func photosManagementSection(_ p: AgencyPropertyDetail) -> some View {
        NavigationLink {
            AgencyPropertyPhotosView(slug: p.slug, photos: p.photos) {
                Task { await vm.reload() }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.maresmeSea.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "photo.stack")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.maresmeSea)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gestionar fotos")
                        .font(.maresmeLabel)
                        .foregroundStyle(Color.maresmeText)
                    Text("\(p.photos.count) foto\(p.photos.count == 1 ? "" : "s") · Subir, eliminar y ordenar")
                        .font(.maresmeCaption)
                        .foregroundStyle(Color.maresmeSubtext)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.maresmeDisabled)
            }
            .padding(16)
            .background(Color.maresmeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Leads section

    private func leadsSection(_ p: AgencyPropertyDetail) -> some View {
        NavigationLink {
            PropertyLeadsView(propertySlug: p.slug, propertyTitle: p.title)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.maresmeBlue.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.badge.clock")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.maresmeBlue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ver leads")
                        .font(.maresmeLabel)
                        .foregroundStyle(Color.maresmeText)
                    Text("\(p.leadsCount) lead\(p.leadsCount == 1 ? "" : "s") de esta propiedad")
                        .font(.maresmeCaption)
                        .foregroundStyle(Color.maresmeSubtext)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.maresmeDisabled)
            }
            .padding(16)
            .background(Color.maresmeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Meta info

    private func metaSection(_ p: AgencyPropertyDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let address = p.address, !address.isEmpty {
                metaRow(label: "Dirección", value: address)
            }
            if let created = p.createdAt {
                metaRow(label: "Creada", value: created.formatted(date: .abbreviated, time: .omitted))
            }
            if let updated = p.updatedAt {
                metaRow(label: "Actualizada", value: updated.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.maresmeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func metaRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.maresmeCaption)
                .foregroundStyle(Color.maresmeSubtext)
            Spacer()
            Text(value)
                .font(.maresmeCaption)
                .foregroundStyle(Color.maresmeText)
        }
    }

    // MARK: - Status badge

    private func statusBadgeView(_ display: AgencyProperty.StatusDisplay) -> some View {
        let fg = statusColor(display.colorName)
        return Text(display.label)
            .font(.maresmeLabelSm)
            .foregroundStyle(fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(fg.opacity(0.12))
            .clipShape(Capsule())
    }

    private func statusColor(_ name: String) -> Color {
        switch name {
        case "success": return .maresmeSuccess
        case "warning": return .maresmeWarning
        case "purple":  return Color.purple
        default:        return .maresmeSubtext
        }
    }

    // MARK: - Loading / Error

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.maresmeBackground)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(Color.maresmeWarning)
            Text(message)
                .font(.maresmeBodySm)
                .foregroundStyle(Color.maresmeSubtext)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Reintentar") { Task { await vm.reload() } }
                .buttonStyle(.bordered)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.maresmeBackground)
    }
}

#Preview {
    NavigationStack {
        AgencyPropertyDetailView(slug: "piso-ejemplo")
    }
}
