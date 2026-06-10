import SwiftUI

struct ActivityRowView: View {
    let activity: AgencyActivity

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            iconCircle
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.message)
                    .font(.maresmeBodySm)
                    .foregroundStyle(Color.maresmeText)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let user = activity.user {
                        Text(user.name)
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeSubtext)
                    }

                    if activity.user != nil, activity.createdAt != nil {
                        Text("·")
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeDisabled)
                    }

                    if let date = activity.createdAt {
                        Text(date.relativeCompact)
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeSubtext)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private var iconCircle: some View {
        ZStack {
            Circle()
                .fill(activityColor.opacity(0.12))
            Image(systemName: activity.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(activityColor)
        }
    }

    private var activityColor: Color {
        switch activity.color {
        case "green":  return .maresmeSuccess
        case "orange": return Color(red: 1.0, green: 0.58, blue: 0.0)
        case "yellow": return .maresmeWarning
        case "purple": return Color.purple
        case "blue":   return .maresmeBlue
        case "indigo": return Color.indigo
        default:       return .maresmeSubtext
        }
    }
}

// MARK: - Date helper

private extension Date {
    var relativeCompact: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
