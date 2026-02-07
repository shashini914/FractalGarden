import Foundation

enum Mandelbrot {

    static func escapeIterations(cx: Double, cy: Double, maxIterations: Int) -> Int {
        var x = 0.0
        var y = 0.0
        var iter = 0

        // Escape radius squared = 4
        while x*x + y*y <= 4.0 && iter < maxIterations {
            // z = z^2 + c
            let xNew = x*x - y*y + cx
            y = 2.0 * x * y + cy
            x = xNew
            iter += 1
        }
        return iter
    }
}

