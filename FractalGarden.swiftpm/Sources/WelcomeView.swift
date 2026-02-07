import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Background gradient (subtle)
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.10),
                    Color(red: 0.10, green: 0.12, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                // Title
                Text("Fractal Garden")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Grow infinite patterns from simple math.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    )
                    .frame(height: 220)
                    .overlay(
                        VStack(spacing: 10) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                            Text("Plant a seed, zoom forever.")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                            Text("Pinch • Pan • Adjust")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.65))
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                Spacer()

                // Start button
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                        appState.screen = .seedSelection
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text("Start")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                Text("Offline • 3-minute experience")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.bottom, 20)
            }
        }
    }
}

