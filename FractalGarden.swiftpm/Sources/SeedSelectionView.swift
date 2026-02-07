import SwiftUI

struct SeedSelectionView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                            appState.screen = .welcome
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(10)
                            .background(.white.opacity(0.08))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("Choose a Seed")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.95))

                    Spacer()

                    // spacer to balance the back button
                    Color.clear.frame(width: 42, height: 42)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                VStack(spacing: 12) {
                    SeedCard(
                        title: "Mandelbrot Seed",
                        subtitle: "Classic infinite garden",
                        icon: "sparkles"
                    ) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                            appState.screen = .cultivate(seed: .mandelbrot)
                        }
                    }

                    SeedCard(
                        title: "Julia Seed",
                        subtitle: "Personalized DNA patterns",
                        icon: "circle.grid.cross"
                    ) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                            appState.screen = .cultivate(seed: .julia)
                        }
                    }

                }
                .padding(.horizontal, 20)

                Spacer()

                Text("Next: we’ll build the Cultivation screen (zoom + sliders).")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.bottom, 20)
            }
        }
    }
}

private struct SeedCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.95))
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(16)
            .background(.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

