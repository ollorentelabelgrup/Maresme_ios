import SwiftUI

struct ActivityView: View {
    @State private var vm = ActivityViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                VStack { Spacer(); ProgressView(); Spacer() }
                    .background(Color.maresmeBackground)
            } else if let error = vm.errorMessage {
                errorView(error)
            } else if vm.activities.isEmpty {
                EmptyStateView(
                    icon:    "clock.arrow.circlepath",
                    title:   "Sin actividad",
                    message: "La actividad de tu agencia aparecerá aquí."
                )
                .background(Color.maresmeBackground)
            } else {
                activityList
            }
        }
        .navigationTitle("Actividad")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
        .refreshable { await vm.reload() }
    }

    // MARK: - List

    private var activityList: some View {
        List {
            ForEach(vm.activities) { activity in
                activityRow(activity)
                    .listRowBackground(Color.maresmeSurface)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .onAppear {
                        if vm.isLastItem(activity) {
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

    @ViewBuilder
    private func activityRow(_ activity: AgencyActivity) -> some View {
        if let prop = activity.property {
            NavigationLink {
                AgencyPropertyDetailView(slug: prop.slug)
            } label: {
                ActivityRowView(activity: activity)
            }
        } else if let lead = activity.lead {
            NavigationLink {
                LeadDetailView(leadId: lead.id)
            } label: {
                ActivityRowView(activity: activity)
            }
        } else {
            ActivityRowView(activity: activity)
        }
    }

    // MARK: - Error

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
        ActivityView()
    }
}
