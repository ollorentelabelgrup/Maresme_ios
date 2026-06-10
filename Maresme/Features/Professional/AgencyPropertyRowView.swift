import SwiftUI

struct AgencyPropertyRowView: View {
    let property: AgencyProperty

    var body: some View {
        HStack(spacing: 14) {
            heroImage
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(property.title)
                    .font(.maresmeBodySm)
                    .foregroundStyle(Color.maresmeText)
                    .lineLimit(2)

                if let price = property.priceFormatted {
                    Text(price)
                        .font(.maresmeLabel)
                        .foregroundStyle(Color.maresmeBlue)
                }

                HStack(spacing: 8) {
                    statusBadge

                    if let municipality = property.municipality {
                        Text(municipality)
                            .font(.maresmeCaption)
                            .foregroundStyle(Color.maresmeSubtext)
                            .lineLimit(1)
                    }
                }

                if property.leadsCount > 0 {
                    Label("\(property.leadsCount) lead\(property.leadsCount == 1 ? "" : "s")", systemImage: "person.badge.clock")
                        .font(.maresmeCaption)
                        .foregroundStyle(Color.maresmeSubtext)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private var heroImage: some View {
        Group {
            if let urlString = property.heroImage, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        propertyPlaceholder
                    }
                }
            } else {
                propertyPlaceholder
            }
        }
    }

    private var propertyPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.maresmeBlue.opacity(0.08))
            Image(systemName: "house.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color.maresmeBlue.opacity(0.4))
        }
    }

    private var statusBadge: some View {
        let display = property.statusDisplay
        return Text(display.label)
            .font(.maresmeLabelSm)
            .foregroundStyle(statusForeground(display.colorName))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusBackground(display.colorName))
            .clipShape(Capsule())
    }

    private func statusForeground(_ colorName: String) -> Color {
        switch colorName {
        case "success": return .maresmeSuccess
        case "warning": return .maresmeWarning
        case "purple":  return Color.purple
        default:        return .maresmeSubtext
        }
    }

    private func statusBackground(_ colorName: String) -> Color {
        statusForeground(colorName).opacity(0.12)
    }
}
