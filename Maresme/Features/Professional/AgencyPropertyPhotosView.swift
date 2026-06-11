import SwiftUI
import PhotosUI

struct AgencyPropertyPhotosView: View {
    @State private var vm: AgencyPropertyPhotosViewModel
    @State private var isEditMode: Bool = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var photoToDelete: AgencyPropertyPhoto? = nil

    private let onPhotosChanged: () -> Void

    init(slug: String, photos: [AgencyPropertyPhoto], onPhotosChanged: @escaping () -> Void) {
        self._vm          = State(initialValue: AgencyPropertyPhotosViewModel(slug: slug, initialPhotos: photos))
        self.onPhotosChanged = onPhotosChanged
    }

    var body: some View {
        Group {
            if vm.photos.isEmpty && !vm.isUploading {
                emptyState
            } else if isEditMode {
                reorderList
            } else {
                photoGrid
            }
        }
        .navigationTitle("Fotos (\(vm.photos.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onChange(of: selectedItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await loadAndUpload(items: items) }
        }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("Aceptar") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .confirmationDialog(
            "¿Eliminar esta foto?",
            isPresented: .constant(photoToDelete != nil),
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                if let photo = photoToDelete {
                    photoToDelete = nil
                    Task {
                        await vm.delete(photo)
                        onPhotosChanged()
                    }
                }
            }
            Button("Cancelar", role: .cancel) { photoToDelete = nil }
        }
    }

    // MARK: - Grid

    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 3
            ) {
                ForEach(vm.photos) { photo in
                    photoCell(photo)
                }

                if vm.isUploading {
                    uploadingCell
                }
            }
        }
        .background(Color.maresmeBackground)
    }

    private func photoCell(_ photo: AgencyPropertyPhoto) -> some View {
        ZStack(alignment: .topLeading) {
            if let url = URL(string: photo.url) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                    default:
                        Color.maresmeBlue.opacity(0.08)
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
            } else {
                Color.maresmeBlue.opacity(0.08)
                    .aspectRatio(1, contentMode: .fill)
            }

            if photo.isPrimary {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(Color.maresmeBlue)
                    .clipShape(Circle())
                    .padding(6)
            }
        }
        .contextMenu {
            if !photo.isPrimary {
                Button {
                    Task {
                        await vm.setPrimary(photo)
                        onPhotosChanged()
                    }
                } label: {
                    Label("Portada", systemImage: "star")
                }
            }
            Button(role: .destructive) {
                photoToDelete = photo
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }

    private var uploadingCell: some View {
        ZStack {
            Color.maresmeBlue.opacity(0.06)
                .aspectRatio(1, contentMode: .fill)
            ProgressView()
        }
    }

    // MARK: - Reorder list

    private var reorderList: some View {
        List {
            ForEach(vm.photos) { photo in
                HStack(spacing: 12) {
                    if let url = URL(string: photo.url) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                                    .frame(width: 56, height: 42)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            default:
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.maresmeBlue.opacity(0.08))
                                    .frame(width: 56, height: 42)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if photo.isPrimary {
                            Text("Portada")
                                .font(.maresmeLabelSm)
                                .foregroundStyle(Color.maresmeBlue)
                        }
                        Text("Foto \(photo.id)")
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeSubtext)
                    }

                    Spacer()
                }
            }
            .onMove { source, destination in
                vm.move(from: source, to: destination)
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(.active))
        .background(Color.maresmeBackground)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
            saveReorderBar
        }
    }

    private var saveReorderBar: some View {
        Button {
            Task {
                await vm.saveReorder()
                if vm.errorMessage == nil {
                    isEditMode = false
                    onPhotosChanged()
                }
            }
        } label: {
            Group {
                if vm.isReordering {
                    ProgressView()
                } else {
                    Text("Guardar orden")
                        .font(.maresmeLabel)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.maresmeBlue)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .disabled(vm.isReordering)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(Color.maresmeBlue.opacity(0.3))
            Text("Sin fotos")
                .font(.maresmeTitle3)
                .foregroundStyle(Color.maresmeText)
            Text("Sube fotos para mejorar la visibilidad de la propiedad.")
                .font(.maresmeBodySm)
                .foregroundStyle(Color.maresmeSubtext)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .background(Color.maresmeBackground)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                if !vm.photos.isEmpty {
                    Button {
                        isEditMode.toggle()
                    } label: {
                        Text(isEditMode ? "Cancelar" : "Reordenar")
                            .font(.maresmeBodySm)
                    }
                }

                if !isEditMode {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .disabled(vm.isUploading)
                }
            }
        }
    }

    // MARK: - Upload helper

    private func loadAndUpload(items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img  = UIImage(data: data) {
                images.append(img)
            }
        }
        selectedItems = []
        guard !images.isEmpty else { return }
        await vm.upload(images: images)
        onPhotosChanged()
    }
}
