import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.maresmeBlue
                .ignoresSafeArea()

            VStack(spacing: 28) {
                // Logo
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.30), radius: 20, x: 0, y: 8)

                // Wordmark
                VStack(spacing: 6) {
                    Text("Maresme")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                    Text("El Maresme, tu nuevo hogar")
                        .font(.maresmeBody)
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
