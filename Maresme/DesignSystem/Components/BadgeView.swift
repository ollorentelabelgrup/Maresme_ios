import SwiftUI

struct BadgeView: View {
    let count: Int

    var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(.maresmeLabelSm)
                .foregroundStyle(.white)
                .padding(.horizontal, count > 9 ? 6 : 5)
                .padding(.vertical, 2)
                .background(Color.maresmeError)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        BadgeView(count: 1)
        BadgeView(count: 12)
        BadgeView(count: 100)
        BadgeView(count: 0)
    }
    .padding()
}
