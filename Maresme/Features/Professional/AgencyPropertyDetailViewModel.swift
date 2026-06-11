import Foundation
import Observation

@Observable
final class AgencyPropertyDetailViewModel {
    var property:        AgencyPropertyDetail? = nil
    var isLoading:       Bool                  = true
    var errorMessage:    String?               = nil
    var isPerformingAction: Bool               = false
    var actionError:     String?               = nil

    private let slug:         String
    private let service:      AgencyPropertyService
    private let writeService: AgencyPropertyWriteService

    init(
        slug: String,
        service: AgencyPropertyService = AgencyPropertyService(),
        writeService: AgencyPropertyWriteService = AgencyPropertyWriteService()
    ) {
        self.slug         = slug
        self.service      = service
        self.writeService = writeService
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

    func applyUpdate(_ updated: AgencyPropertyDetail) {
        property = updated
    }

    // MARK: - State machine actions

    func perform(_ action: AgencyPropertyDetail.PropertyAction) async {
        guard let p = property, !isPerformingAction else { return }
        isPerformingAction = true
        actionError = nil
        do {
            let updated: AgencyPropertyDetail
            switch action {
            case .publish:
                updated = try await writeService.publish(slug: p.slug)
            case .unpublish:
                updated = try await writeService.unpublish(slug: p.slug)
            case .reserve:
                updated = try await writeService.changeStatus(slug: p.slug, to: "reserved")
            case .reactivate:
                updated = try await writeService.changeStatus(slug: p.slug, to: "active")
            case .sell:
                updated = try await writeService.changeStatus(slug: p.slug, to: "sold")
            }
            property = updated
        } catch {
            actionError = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isPerformingAction = false
    }
}
