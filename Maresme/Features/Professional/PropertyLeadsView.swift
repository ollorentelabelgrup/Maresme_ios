import SwiftUI
import Observation

// Leads de una propiedad concreta — GET /api/v1/agency/properties/{slug}/leads

@Observable
private final class PropertyLeadsViewModel {
    var leads:         [AgencyLead] = []
    var isLoading:     Bool         = true
    var isLoadingMore: Bool         = false
    var errorMessage:  String?      = nil

    private var nextCursor: String? = nil
    private var hasMore:    Bool    = true
    private let propertySlug: String
    private let service       = AgencyPropertyService()

    init(slug: String) { self.propertySlug = slug }

    func load() async {
        errorMessage = nil
        nextCursor   = nil
        hasMore      = true
        do {
            let page = try await service.leads(slug: propertySlug)
            leads    = page.data
            nextCursor = page.nextCursor
            hasMore    = page.nextCursor != nil
        } catch {
            errorMessage = (error as? APIError)?.localizedDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore, let cursor = nextCursor else { return }
        isLoadingMore = true
        do {
            let page = try await service.leads(slug: propertySlug, cursor: cursor)
            leads.append(contentsOf: page.data)
            nextCursor = page.nextCursor
            hasMore    = page.nextCursor != nil
        } catch { }
        isLoadingMore = false
    }
}

struct PropertyLeadsView: View {
    let propertySlug:  String
    let propertyTitle: String

    @State private var vm: PropertyLeadsViewModel

    init(propertySlug: String, propertyTitle: String) {
        self.propertySlug  = propertySlug
        self.propertyTitle = propertyTitle
        self._vm = State(initialValue: PropertyLeadsViewModel(slug: propertySlug))
    }

    var body: some View {
        Group {
            if vm.isLoading {
                VStack { Spacer(); ProgressView(); Spacer() }
            } else if let error = vm.errorMessage {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.maresmeWarning)
                    Text(error)
                        .font(.maresmeBodySm)
                        .foregroundStyle(Color.maresmeSubtext)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
            } else if vm.leads.isEmpty {
                EmptyStateView(
                    icon:    "person.badge.clock",
                    title:   "Sin leads",
                    message: "Esta propiedad aún no tiene leads."
                )
            } else {
                List {
                    ForEach(vm.leads) { lead in
                        NavigationLink {
                            LeadDetailView(leadId: lead.id)
                        } label: {
                            LeadRowView(lead: lead)
                        }
                        .listRowBackground(Color.maresmeSurface)
                        .onAppear {
                            if vm.leads.last?.id == lead.id {
                                Task { await vm.loadMore() }
                            }
                        }
                    }
                    if vm.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView().padding(.vertical, 8)
                            Spacer()
                        }
                        .listRowBackground(Color.maresmeBackground)
                    }
                }
                .listStyle(.plain)
                .background(Color.maresmeBackground)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Leads")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.maresmeBackground)
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }
}
