import Foundation
import CoreGraphics
import UIKit

enum PaletteOption: CaseIterable, Equatable {
    case ocean
    case heat
    case neon
    case mono

    var displayName: String {
        switch self {
        case .ocean: return "Ocean"
        case .heat: return "Heat"
        case .neon: return "Neon"
        case .mono: return "Mono"
        }
    }
}

struct FractalParams: Equatable {
    var width: Int
    var height: Int
    var maxIterations: Int

    // View window in the complex plane
    var centerX: Double   // real
    var centerY: Double   // imag
    var scale: Double     // half-width of view (smaller = more zoom)
    var palette: PaletteOption
}

final class FractalRenderer {

    func renderMandelbrot(_ p: FractalParams) -> CGImage? {
        let w = max(1, p.width)
        let h = max(1, p.height)
        let maxI = max(10, p.maxIterations)

        // RGBA buffer
        var pixels = [UInt8](repeating: 0, count: w * h * 4)

        let aspect = Double(h) / Double(w)
        let halfWidth = p.scale
        let halfHeight = p.scale * aspect

        let minX = p.centerX - halfWidth
        let maxX = p.centerX + halfWidth
        let minY = p.centerY - halfHeight
        let maxY = p.centerY + halfHeight

        for y in 0..<h {
            let cy = minY + (Double(y) / Double(h - 1)) * (maxY - minY)
            for x in 0..<w {
                let cx = minX + (Double(x) / Double(w - 1)) * (maxX - minX)

                let iter = Mandelbrot.escapeIterations(cx: cx, cy: cy, maxIterations: maxI)

                let t = Double(iter) / Double(maxI) // 0..1
                let rgba = colorRGBA(t: t, escaped: iter < maxI, palette: p.palette)

                let idx = (y * w + x) * 4
                pixels[idx + 0] = rgba.r
                pixels[idx + 1] = rgba.g
                pixels[idx + 2] = rgba.b
                pixels[idx + 3] = 255
            }
        }

        // Create CGImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        return pixels.withUnsafeBytes { buf in
            guard let base = buf.baseAddress else { return nil }
            guard let ctx = CGContext(
                data: UnsafeMutableRawPointer(mutating: base),
                width: w,
                height: h,
                bitsPerComponent: 8,
                bytesPerRow: w * 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            ) else { return nil }
            return ctx.makeImage()
        }
    }


    private struct RGBA { var r: UInt8; var g: UInt8; var b: UInt8 }

    private func colorRGBA(t: Double, escaped: Bool, palette: PaletteOption) -> RGBA {
        if !escaped {
            
            return RGBA(r: 10, g: 10, b: 12)
        }

        // Smooth-ish curve so low iterations aren’t too dark
        let s = pow(t, 0.65)

        switch palette {
        case .mono:
            let v = UInt8(30 + 220 * s)
            return RGBA(r: v, g: v, b: v)

        case .ocean:
            // Blue -> Cyan -> Mint
            let r = UInt8(10 + 40 * s)
            let g = UInt8(40 + 200 * s)
            let b = UInt8(80 + 160 * s)
            return RGBA(r: r, g: g, b: b)

        case .heat:
            // Dark red -> orange -> yellow
            let r = UInt8(60 + 195 * s)
            let g = UInt8(10 + 190 * s)
            let b = UInt8(10 + 40 * s)
            return RGBA(r: r, g: g, b: b)

        case .neon:
            // Pink -> Purple -> Cyan
            let r = UInt8(100 + 155 * (1.0 - s))
            let g = UInt8(20 + 160 * s)
            let b = UInt8(140 + 115 * s)
            return RGBA(r: r, g: g, b: b)
        }
    }
}

