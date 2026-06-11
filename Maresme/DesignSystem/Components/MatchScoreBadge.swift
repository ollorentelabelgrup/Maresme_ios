import SwiftUI

// Muestra la compatibilidad numérica y cualitativa de una recomendación.
// Modo compact: cápsula inline para listas.
// Modo full (default): círculo de progreso + etiqueta para el detalle.
struct MatchScoreBadge: View {
    let score:   Int
    let quality: String
    var compact: Bool = false

    var body: some View {
        if compact {
            compactBadge
        } else {
            fullBadge
        }
    }

    // MARK: - Compact (inline en listas)

    private var compactBadge: some View {
        HStack(spacing: 4) {
            Text("\(score)")
                .font(.maresmeLabel)
            Text(qualityLabel)
                .font(.maresmeLabelSm)
        }
        .foregroundStyle(scoreColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(scoreColor.opacity(0.10))
        .clipShape(Capsule())
    }

    // MARK: - Full (detalle)

    private var fullBadge: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.15), lineWidth: 4)
                    .frame(width: 68, height: 68)
                Circle()
                    .trim(from: 0, to: CGFloat(min(score, 100)) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 68, height: 68)
                    .rotationEffect(.degrees(-90))
                Text("\(score)")
                    .font(.maresmeTitle3)
                    .foregroundStyle(scoreColor)
            }
            Text(qualityLabel)
                .font(.maresmeLabelSm)
                .foregroundStyle(scoreColor)
        }
    }

    // MARK: - Helpers

    var qualityLabel: String {
        switch quality {
        case "excellent": return "Excelente"
        case "very_high": return "Muy alta"
        case "high":      return "Alta"
        case "medium":    return "Media"
        default:          return "Básica"
        }
    }

    var scoreColor: Color {
        switch quality {
        case "excellent": return Color(red: 0.09, green: 0.64, blue: 0.27)
        case "very_high": return Color.maresmeSuccess
        case "high":      return Color.maresmeBlue
        case "medium":    return Color.maresmeWarning
        default:          return Color.maresmeDisabled
        }
    }
}

#Preview("Compact") {
    VStack(spacing: 12) {
        HStack(spacing: 10) {
            MatchScoreBadge(score: 96, quality: "excellent", compact: true)
            MatchScoreBadge(score: 84, quality: "very_high", compact: true)
            MatchScoreBadge(score: 73, quality: "high",      compact: true)
            MatchScoreBadge(score: 66, quality: "medium",    compact: true)
        }
    }
    .padding()
    .background(Color.maresmeBackground)
}

#Preview("Full") {
    HStack(spacing: 24) {
        MatchScoreBadge(score: 96, quality: "excellent")
        MatchScoreBadge(score: 84, quality: "very_high")
        MatchScoreBadge(score: 73, quality: "high")
        MatchScoreBadge(score: 66, quality: "medium")
    }
    .padding()
    .background(Color.maresmeBackground)
}
