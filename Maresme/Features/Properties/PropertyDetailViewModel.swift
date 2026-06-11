import Foundation

@Observable
final class PropertyDetailViewModel {
    var property:     PropertyDetail? = nil
    var isLoading:    Bool            = true
    var errorMessage: String?         = nil

    private let slug:    String
    private let service: PropertyService

    init(slug: String, service: PropertyService = PropertyService()) {
        self.slug    = slug
        self.service = service
    }

    func load() async {
        guard isLoading else { return }
        errorMessage = nil

        do {
            property  = try await service.detail(slug: slug)
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    // Reload after a failed load (user tapped "Reintentar")
    func reload() async {
        isLoading    = true
        errorMessage = nil
        await load()
    }
}
