import SwiftUI
import CoreGraphics

struct CultivateView: View {
    @EnvironmentObject var appState: AppState

    // Controls
    @State private var iterations: Double = 180
    @State private var growthSpeed: Double = 0.6
    @State private var palette: PaletteOption = .ocean

    // Fractal "camera" (complex plane)
    @State private var centerX: Double = -0.5
    @State private var centerY: Double = 0.0
    @State private var scale: Double = 1.35
    private let initialScale: Double = 1.35

    // Gesture state (visual-only while moving)
    @State private var liveMagnify: CGFloat = 1.0
    @State private var liveDrag: CGSize = .zero
    @State private var canvasSize: CGSize = .zero

    // Render output
    @State private var fractalImage: CGImage? = nil
    @State private var isRendering: Bool = false
    @State private var renderTaskID: Int = 0

    private let renderer = FractalRenderer()

    private var seedName: String {
        if case let .cultivate(seed) = appState.screen {
            return seed.rawValue
        }
        return appState.selectedSeed.rawValue
    }

    private var zoomValue: CGFloat {
        // When scale decreases, zoom increases
        CGFloat(initialScale / scale)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 14) {

                // Top bar
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                            appState.screen = .seedSelection
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.95))
                            .padding(10)
                            .background(.white.opacity(0.08))
                            .clipShape(Circle())
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cultivation")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.95))
                        Text("\(seedName) Seed • Pinch & Pan")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    Button {
                
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // Canvas (real image + gestures)
                FractalCanvasView(
                    image: fractalImage,
                    isRendering: isRendering,
                    liveMagnify: $liveMagnify,
                    liveDrag: $liveDrag,
                    onCanvasSize: { size in
                        self.canvasSize = size
                    },
                    onGestureCommit: { magnifyValue, dragValue in
                        commitGesture(magnifyValue: magnifyValue, dragValue: dragValue)
                    }
                )
                .overlay(alignment: .topLeading) {
                    ZoomBadge(zoom: zoomValue)
                        .padding(12)
                }
                .overlay(alignment: .topTrailing) {
                    PaletteBadge(name: palette.displayName)
                        .padding(12)
                }
                .padding(.horizontal, 16)
                .onAppear {
                    renderFractal()
                }
                .onChange(of: iterations) { _ in
                    renderFractal()
                }
                .onChange(of: palette) { _ in
                    renderFractal()
                }

                // Controls panel
                ControlPanel(
                    iterations: $iterations,
                    growthSpeed: $growthSpeed,
                    palette: $palette,
                    onReset: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                            iterations = 180
                            growthSpeed = 0.6
                            palette = .ocean

                            // Reset camera
                            centerX = -0.5
                            centerY = 0.0
                            scale = initialScale

                            // Reset gesture visuals
                            liveMagnify = 1.0
                            liveDrag = .zero
                        }
                        renderFractal()
                    },
                    onAnimate: {
                        withAnimation(.easeInOut(duration: 0.7).repeatCount(2, autoreverses: true)) {
                            liveMagnify = 1.06
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                liveMagnify = 1.0
                            }
                        }
                    }
                )
                .padding(.horizontal, 16)

                Spacer(minLength: 8)
            }
        }
    }

    private func commitGesture(magnifyValue: CGFloat, dragValue: CGSize) {
        let newScale = scale / Double(magnifyValue)
        scale = max(0.0005, min(newScale, 4.0))

        guard canvasSize.width > 0, canvasSize.height > 0 else {
            liveMagnify = 1.0
            liveDrag = .zero
            renderFractal()
            return
        }

        let w = Double(canvasSize.width)
        let h = Double(canvasSize.height)
        let aspect = h / w

        let dx = Double(dragValue.width)
        let dy = Double(dragValue.height)

        // Width in complex plane = 2*scale, Height = 2*scale*aspect
        let deltaX = (dx / w) * (2.0 * scale)
        let deltaY = (dy / h) * (2.0 * scale * aspect)

        // Move camera opposite to the drag (typical map feel)
        centerX -= deltaX
        centerY -= deltaY

        // 3) Reset visual-only gesture state
        liveMagnify = 1.0
        liveDrag = .zero

        // 4) Re-render
        renderFractal()
    }

    // MARK: - Rendering

    private func renderFractal() {
        renderTaskID += 1
        let currentID = renderTaskID

        isRendering = true

        // If it's slow, reduce to 320x320.
        let params = FractalParams(
            width: 420,
            height: 420,
            maxIterations: Int(iterations),
            centerX: centerX,
            centerY: centerY,
            scale: scale,
            palette: palette
        )

        DispatchQueue.global(qos: .userInitiated).async {
            let img = renderer.renderMandelbrot(params)

            DispatchQueue.main.async {
                guard currentID == renderTaskID else { return }
                self.fractalImage = img
                self.isRendering = false
            }
        }
    }
}

private struct FractalCanvasView: View {
    let image: CGImage?
    let isRendering: Bool

    @Binding var liveMagnify: CGFloat
    @Binding var liveDrag: CGSize

    let onCanvasSize: (CGSize) -> Void
    let onGestureCommit: (CGFloat, CGSize) -> Void

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            RoundedRectangle(cornerRadius: 22)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
                .overlay {
                    ZStack {
                        if let img = image {
                            Image(decorative: img, scale: 1.0)
                                .resizable()
                                .scaledToFill()
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                // Smooth visual transforms while moving
                                .scaleEffect(liveMagnify)
                                .offset(liveDrag)
                                .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.9), value: liveDrag)
                        } else {
                            VStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                Text("Growing your garden…")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }

                        if isRendering {
                            VStack(spacing: 10) {
                                ProgressView().tint(.white.opacity(0.85))
                                Text("Rendering…")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                            .padding(14)
                            .background(.black.opacity(0.55))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.12), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .onAppear { onCanvasSize(size) }
                .onChange(of: size) { onCanvasSize($0) }
                .gesture(panGesture)
                .simultaneousGesture(pinchGesture)
        }
        .frame(height: 360)
    }

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                liveDrag = value.translation
            }
            .onEnded { value in
                onGestureCommit(liveMagnify, value.translation)
            }
    }

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                liveMagnify = value
            }
            .onEnded { value in
                onGestureCommit(value, liveDrag)
            }
    }
}

private struct ZoomBadge: View {
    let zoom: CGFloat

    var body: some View {
        Text(String(format: "Zoom %.2fx", zoom))
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(.black.opacity(0.55))
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 999))
    }
}

private struct PaletteBadge: View {
    let name: String

    var body: some View {
        Text(name)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(.black.opacity(0.55))
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 999))
    }
}

private struct ControlPanel: View {
    @Binding var iterations: Double
    @Binding var growthSpeed: Double
    @Binding var palette: PaletteOption

    let onReset: () -> Void
    let onAnimate: () -> Void

    var body: some View {
        VStack(spacing: 12) {

            // Iterations
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Iterations")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    Text("\(Int(iterations))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.65))
                }
                Slider(value: $iterations, in: 50...600, step: 10)
            }

            // Growth speed (UI feel, not compute speed)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Growth Speed")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    Text(String(format: "%.0f%%", growthSpeed * 100))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.65))
                }
                Slider(value: $growthSpeed, in: 0.2...1.0, step: 0.05)
            }

            // Palette
            VStack(alignment: .leading, spacing: 8) {
                Text("Palette")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))

                HStack(spacing: 10) {
                    ForEach(PaletteOption.allCases, id: \.self) { option in
                        PaletteChip(option: option, isSelected: option == palette) {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                                palette = option
                            }
                        }
                    }
                }
            }

            // Buttons
            HStack(spacing: 12) {
                Button(action: onReset) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button(action: onAnimate) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Animate")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

private struct PaletteChip: View {
    let option: PaletteOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 999)
                    .fill(chipGradient(for: option))
                    .frame(width: 22, height: 10)

                Text(option.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(isSelected ? 0.95 : 0.70))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(isSelected ? .white.opacity(0.12) : .white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(.white.opacity(isSelected ? 0.18 : 0.10), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 999))
        }
        .buttonStyle(.plain)
    }

    private func chipGradient(for option: PaletteOption) -> LinearGradient {
        switch option {
        case .ocean:
            return LinearGradient(colors: [.blue, .cyan, .mint], startPoint: .leading, endPoint: .trailing)
        case .heat:
            return LinearGradient(colors: [.red, .orange, .yellow], startPoint: .leading, endPoint: .trailing)
        case .neon:
            return LinearGradient(colors: [.pink, .purple, .cyan], startPoint: .leading, endPoint: .trailing)
        case .mono:
            return LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.85)], startPoint: .leading, endPoint: .trailing)
        }
    }
}

