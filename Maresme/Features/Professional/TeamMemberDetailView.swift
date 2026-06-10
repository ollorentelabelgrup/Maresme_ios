import SwiftUI

struct TeamMemberDetailView: View {
    let member: AgencyTeamMember

    var body: some View {
        List {
            avatarSection
            infoSection
            metricsSection
        }
        .listStyle(.insetGrouped)
        .background(Color.maresmeBackground)
        .scrollContentBackground(.hidden)
        .navigationTitle(member.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.maresmeBlue, Color.maresmeSea],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 72, height: 72)
                        Text(member.initials)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    VStack(spacing: 4) {
                        Text(member.name)
                            .font(.maresmeTitle3)
                            .foregroundStyle(Color.maresmeText)
                        Text(member.roleLabel)
                            .font(.maresmeLabelSm)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(roleColor)
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }
            .padding(.vertical, 16)
            .listRowBackground(Color.maresmeBackground)
            .listRowInsets(EdgeInsets())
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        Section("Información") {
            LabeledContent("Email", value: member.email)
            if let joined = member.joinedAt {
                LabeledContent("En el equipo desde", value: joined.formatted(date: .abbreviated, time: .omitted))
            }
        }
    }

    // MARK: - Metrics

    private var metricsSection: some View {
        Section("Rendimiento en leads") {
            metricRow(label: "Leads totales asignados", value: member.totalLeads, color: .maresmeText)
            metricRow(label: "Leads abiertos",          value: member.openLeads, color: .maresmeBlue)
            metricRow(label: "Leads convertidos",       value: member.convertedLeads, color: .maresmeSuccess)
        }
    }

    private func metricRow(label: String, value: Int, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.maresmeBodySm)
                .foregroundStyle(Color.maresmeText)
            Spacer()
            Text("\(value)")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
        }
    }

    private var roleColor: Color {
        switch member.role {
        case "owner":   return Color.maresmeError
        case "manager": return Color.maresmeSea
        default:        return Color.maresmeBlue
        }
    }
}

#Preview {
    NavigationStack {
        TeamMemberDetailView(member: AgencyTeamMember(
            id: 1, name: "Jordi Puig", email: "jordi@example.com",
            role: "owner", roleLabel: "Propietario", isActive: true,
            acceptedAt: Date(), joinedAt: Date(),
            totalLeads: 12, openLeads: 5, convertedLeads: 3
        ))
    }
}
