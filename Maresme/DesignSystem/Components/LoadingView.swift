import SwiftUI

struct LoadingView: View {
    var message: String?

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)
            if let message {
                Text(message)
                    .font(.maresmeBodySm)
                    .foregroundStyle(Color.maresmeSubtext)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingView(message: "Cargando propiedades...")
}
