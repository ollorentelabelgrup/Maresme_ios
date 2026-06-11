import Foundation

@Observable
final class RecommendationDetailViewModel {
    var detail:    RecommendationDetail? = nil
    var isLoading: Bool                  = false
    var error:     String?               = nil

    private let slug:    String
    private let service: RecommendationService

    init(slug: String, service: RecommendationService = RecommendationService()) {
        self.slug    = slug
        self.service = service
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error     = nil

        do {
            detail = try await service.show(slug: slug)
        } catch {
            self.error = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
