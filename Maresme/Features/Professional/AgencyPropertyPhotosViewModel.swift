import Foundation
import Observation
import SwiftUI

@Observable
final class AgencyPropertyPhotosViewModel {
    var photos:        [AgencyPropertyPhoto] = []
    var isUploading:   Bool                  = false
    var isReordering:  Bool                  = false
    var errorMessage:  String?               = nil

    private let propertySlug: String
    private let writeService: AgencyPropertyWriteService

    init(slug: String, initialPhotos: [AgencyPropertyPhoto],
         writeService: AgencyPropertyWriteService = AgencyPropertyWriteService()) {
        self.propertySlug = slug
        self.photos       = initialPhotos
        self.writeService = writeService
    }

    // MARK: - Upload

    func upload(images: [UIImage]) async {
        guard !isUploading else { return }
        isUploading  = true
        errorMessage = nil
        do {
            let uploaded = try await writeService.uploadPhotos(slug: propertySlug, images: images)
            photos.append(contentsOf: uploaded)
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isUploading = false
    }

    // MARK: - Delete

    func delete(_ photo: AgencyPropertyPhoto) async {
        errorMessage = nil
        do {
            try await writeService.deletePhoto(propertySlug: propertySlug, photoId: photo.id)
            photos.removeAll { $0.id == photo.id }
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
    }

    // MARK: - Set primary

    func setPrimary(_ photo: AgencyPropertyPhoto) async {
        errorMessage = nil
        do {
            let updated = try await writeService.setPrimaryPhoto(propertySlug: propertySlug, photoId: photo.id)
            photos = updated
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
    }

    // MARK: - Reorder (local move + server save)

    func move(from source: IndexSet, to destination: Int) {
        photos.move(fromOffsets: source, toOffset: destination)
    }

    func saveReorder() async {
        guard !isReordering else { return }
        isReordering = true
        errorMessage = nil
        do {
            let order = photos.map(\.id)
            let updated = try await writeService.reorderPhotos(propertySlug: propertySlug, order: order)
            photos = updated
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isReordering = false
    }
}
