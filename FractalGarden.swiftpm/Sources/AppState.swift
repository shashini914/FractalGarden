import Foundation

enum AppScreen {
    case welcome
    case seedSelection
    case cultivate(seed: FractalSeed)
}

enum FractalSeed: String {
    case mandelbrot = "Mandelbrot"
    case julia = "Julia"
}

final class AppState: ObservableObject {
    @Published var screen: AppScreen = .welcome
    @Published var selectedSeed: FractalSeed = .mandelbrot
}

