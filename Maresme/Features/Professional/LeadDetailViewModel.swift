import Foundation
import Observation

@Observable
final class LeadDetailViewModel {
    var lead:         AgencyLeadDetail? = nil
    var isLoading:    Bool              = true
    var errorMessage: String?           = nil

    private let leadId:  Int
    private let service: AgencyLeadService

    init(leadId: Int, service: AgencyLeadService = AgencyLeadService()) {
        self.leadId  = leadId
        self.service = service
    }

    func load() async {
        guard isLoading else { return }
        errorMessage = nil
        do {
            lead = try await service.detail(id: leadId)
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
