import SwiftUI

struct TeamMemberRowView: View {
    let member: AgencyTeamMember

    var body: some View {
        HStack(spacing: 14) {
            initialsCircle
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.maresmeBodySm)
                    .foregroundStyle(Color.maresmeText)

                roleBadge
            }

            Spacer(minLength: 0)

            metricsStack
        }
        .padding(.vertical, 4)
    }

    private var initialsCircle: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [Color.maresmeBlue, Color.maresmeSea],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            Text(member.initials)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var roleBadge: some View {
        Text(member.roleLabel)
            .font(.maresmeLabelSm)
            .foregroundStyle(roleColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(roleColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private var roleColor: Color {
        switch member.role {
        case "owner":   return Color.maresmeError
        case "manager": return Color.maresmeSea
        default:        return Color.maresmeBlue
        }
    }

    private var metricsStack: some View {
        HStack(spacing: 12) {
            metricBadge(value: member.totalLeads,     label: "total",  color: .maresmeSubtext)
            metricBadge(value: member.openLeads,      label: "abiertos", color: .maresmeBlue)
            metricBadge(value: member.convertedLeads, label: "conv.",   color: .maresmeSuccess)
        }
    }

    private func metricBadge(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(Color.maresmeSubtext)
        }
    }
}
