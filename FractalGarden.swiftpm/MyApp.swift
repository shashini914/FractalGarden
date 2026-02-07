import SwiftUI

@main
struct FractalGardenApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        switch appState.screen {
        case .welcome:
            WelcomeView()
        case .seedSelection:
            SeedSelectionView()
        case .cultivate:
            CultivateView()
        }

    }
}

