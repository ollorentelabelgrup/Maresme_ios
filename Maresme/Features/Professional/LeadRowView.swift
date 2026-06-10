import SwiftUI

struct LeadRowView: View {
    let lead: AgencyLead

    var body: some View {
        HStack(spacing: 14) {
            initialsCircle
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(lead.name)
                    .font(.maresmeBodySm)
                    .foregroundStyle(Color.maresmeText)

                if let prop = lead.property {
                    Text(prop.title)
                        .font(.maresmeCaption)
                        .foregroundStyle(Color.maresmeSubtext)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    statusBadge

                    if let quality = lead.leadQuality {
                        Text(quality.capitalized)
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeSubtext)
                    }
                }
            }

            Spacer(minLength: 0)

            if let date = lead.createdAt {
                Text(date.relativeFormatted)
                    .font(.maresmeCaption)
                    .foregroundStyle(Color.maresmeSubtext)
            }
        }
        .padding(.vertical, 4)
    }

    private var initialsCircle: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [Color.maresmeBlue.opacity(0.7), Color.maresmeSea.opacity(0.7)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            Text(String(lead.name.prefix(1)).uppercased())
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var statusBadge: some View {
        Text(lead.statusLabel)
            .font(.maresmeLabelSm)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch lead.statusColor {
        case "green":  return .maresmeSuccess
        case "blue":   return .maresmeBlue
        case "yellow": return .maresmeWarning
        case "red":    return .maresmeError
        case "gray":   return .maresmeSubtext
        default:       return .maresmeSubtext
        }
    }
}

// MARK: - Date helper

private extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
