import SwiftUI

struct PrimaryButton: View {
    let title:    String
    let isLoading: Bool
    let action:   () -> Void

    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title     = title
        self.isLoading = isLoading
        self.action    = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.maresmeLabelLg)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.maresmeBlue)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("Iniciar sesión") {}
        PrimaryButton("Cargando...", isLoading: true) {}
    }
    .padding()
}
