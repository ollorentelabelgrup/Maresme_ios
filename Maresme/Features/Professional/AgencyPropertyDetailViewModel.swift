import Foundation
import Observation

@Observable
final class AgencyPropertyDetailViewModel {
    var property:     AgencyPropertyDetail? = nil
    var isLoading:    Bool                  = true
    var errorMessage: String?               = nil

    private let slug:    String
    private let service: AgencyPropertyService

    init(slug: String, service: AgencyPropertyService = AgencyPropertyService()) {
        self.slug    = slug
        self.service = service
    }

    func load() async {
        guard isLoading else { return }
        errorMessage = nil
        do {
            property = try await service.detail(slug: slug)
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    func reload() async {
        isLoading    = true
        errorMessage = nil
        await load()
    }
}
