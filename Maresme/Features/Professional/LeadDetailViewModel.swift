import Foundation
import Observation

@Observable
final class LeadDetailViewModel {
    var lead:          AgencyLeadDetail? = nil
    var isLoading:     Bool              = true
    var errorMessage:  String?           = nil
    var isSaving:      Bool              = false
    var saveError:     String?           = nil
    var teamMembers:   [AgencyTeamMember] = []

    private let leadId:       Int
    private let service:      AgencyLeadService
    private let writeService: AgencyLeadWriteService
    private let teamService:  AgencyTeamService

    init(
        leadId: Int,
        service: AgencyLeadService = AgencyLeadService(),
        writeService: AgencyLeadWriteService = AgencyLeadWriteService(),
        teamService: AgencyTeamService = AgencyTeamService()
    ) {
        self.leadId       = leadId
        self.service      = service
        self.writeService = writeService
        self.teamService  = teamService
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

    // MARK: - Write actions

    func updateStatus(_ status: String) async {
        await performWrite { [weak self] in
            guard let self else { return }
            lead = try await writeService.update(leadId: leadId, status: status)
        }
    }

    func updateLeadQuality(_ quality: String) async {
        await performWrite { [weak self] in
            guard let self else { return }
            lead = try await writeService.update(leadId: leadId, leadQuality: quality)
        }
    }

    func updateBuyerStage(_ stage: String) async {
        await performWrite { [weak self] in
            guard let self else { return }
            lead = try await writeService.update(leadId: leadId, buyerStage: stage)
        }
    }

    func addNote(_ text: String) async {
        await performWrite { [weak self] in
            guard let self else { return }
            let _ = try await writeService.addNote(leadId: leadId, note: text)
            lead = try await service.detail(id: leadId)
        }
    }

    func assign(to userId: Int) async {
        await performWrite { [weak self] in
            guard let self else { return }
            lead = try await writeService.assign(leadId: leadId, userId: userId)
        }
    }

    func loadTeam() async {
        guard teamMembers.isEmpty else { return }
        if let members = try? await teamService.list() {
            teamMembers = members
        }
    }

    // MARK: - Private

    private func performWrite(_ block: @escaping () async throws -> Void) async {
        guard !isSaving else { return }
        isSaving   = true
        saveError  = nil
        do {
            try await block()
        } catch {
            saveError = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isSaving = false
    }
}
