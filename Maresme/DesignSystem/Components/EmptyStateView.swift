import SwiftUI

struct EmptyStateView: View {
    let icon:    String
    let title:   String
    let message: String
    var action:  (() -> Void)?
    var actionTitle: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.maresmeDisabled)

            VStack(spacing: 6) {
                Text(title)
                    .font(.maresmeTitle3)
                    .foregroundStyle(Color.maresmeText)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.maresmeBody)
                    .foregroundStyle(Color.maresmeSubtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let action, let actionTitle {
                Button(actionTitle, action: action)
                    .font(.maresmeLabel)
                    .foregroundStyle(Color.maresmeBlue)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    EmptyStateView(
        icon:    "heart.slash",
        title:   "Sin favoritos",
        message: "Guarda propiedades para verlas aquí.",
        action:  {},
        actionTitle: "Explorar propiedades"
    )
}
