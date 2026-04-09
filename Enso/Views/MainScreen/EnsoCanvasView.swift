import SwiftUI

struct EnsoCanvasView: View {
    let progress: Double
    let isDark: Bool

    private let canvasSize: CGFloat = EnsoTheme.ensoSize

    var body: some View {
        Canvas { context, size in
            drawEnso(context: context, size: size, progress: progress)
        }
        .frame(width: canvasSize, height: canvasSize)
    }

    private func drawEnso(context: GraphicsContext, size: CGSize, progress p: Double) {
        guard p > 0.005 else { return }

        let w = size.width
        let cx = w / 2
        let cy = size.height / 2
        let radius = w * EnsoTheme.ensoRadius

        let arcExtent: Double = p < 1
            ? (0.12 + p * 0.83) * .pi * 2
            : .pi * 2 * 0.94
        let startAngle = EnsoTheme.ensoStartAngle

        let baseWidth: CGFloat = 5 + CGFloat(p) * 18
        let baseAlpha: Double = 0.06 + p * 0.88

        let steps = 300

        func noise(_ i: Int) -> Double {
            let x = sin(Double(i) * 127.1 + 42) * 43758.5453
            return x - floor(x)
        }

        for i in 0..<steps {
            let t = Double(i) / Double(steps)
            let tNext = Double(i + 1) / Double(steps)

            let angle = startAngle + t * arcExtent
            let angleNext = startAngle + tNext * arcExtent

            let w1 = sin(t * 53.7) * 1.8
            let w2 = cos(t * 37.3) * 1.1
            let w3 = (noise(i) - 0.5) * 1.4
            let wobble = CGFloat(w1 + w2 + w3)

            let pressure: Double
            if t < 0.06 {
                pressure = t / 0.06
            } else if t < 0.25 {
                pressure = 1.0 - (t - 0.06) * 1.2
            } else if t < 0.7 {
                pressure = 0.55 + sin((t - 0.25) * 3.5) * 0.15
            } else if t < 0.88 {
                pressure = 0.55 + (t - 0.7) * 2.5
            } else {
                pressure = max(0, 1.0 - (t - 0.88) * 8.3)
            }

            let currentWidth = baseWidth * CGFloat(0.4 + pressure * 0.6)
            let alphaVar = 0.9 + sin(t * 19) * 0.1
            let alpha = min(baseAlpha * (0.8 + pressure * 0.2) * alphaVar, 0.95)

            let r1 = radius + wobble
            let x1 = cx + cos(angle) * r1
            let y1 = cy + sin(angle) * r1
            let x2 = cx + cos(angleNext) * r1
            let y2 = cy + sin(angleNext) * r1

            var path = Path()
            path.move(to: CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x2, y: y2))

            let inkColor = isDark
                ? Color(red: 228/255, green: 223/255, blue: 214/255).opacity(alpha)
                : Color(red: 38/255, green: 36/255, blue: 34/255).opacity(alpha)

            context.stroke(
                path,
                with: .color(inkColor),
                style: StrokeStyle(lineWidth: currentWidth, lineCap: .round)
            )
        }

        if p > 0.15 {
            let splatCount = Int(p * 12)
            for i in 0..<splatCount {
                let t = noise(i + 1000)
                let angle = startAngle + t * arcExtent
                let offset = CGFloat(noise(i + 2000) - 0.5) * baseWidth * 2.5
                let perpAngle = angle + .pi / 2
                let sx = cx + cos(angle) * radius + cos(perpAngle) * offset
                let sy = cy + sin(angle) * radius + sin(perpAngle) * offset
                let sr = CGFloat(noise(i + 3000)) * 1.2 + 0.2

                let splatAlpha = baseAlpha * 0.25 * noise(i + 4000)
                let splatColor = isDark
                    ? Color(red: 228/255, green: 223/255, blue: 214/255).opacity(splatAlpha)
                    : Color(red: 38/255, green: 36/255, blue: 34/255).opacity(splatAlpha)

                context.fill(
                    Path(ellipseIn: CGRect(x: sx - sr, y: sy - sr, width: sr * 2, height: sr * 2)),
                    with: .color(splatColor)
                )
            }
        }

        if p >= 1 {
            let glowColor = isDark
                ? Color(red: 228/255, green: 223/255, blue: 214/255)
                : Color(red: 38/255, green: 36/255, blue: 34/255)

            context.fill(
                Path(ellipseIn: CGRect(
                    x: cx - radius * 1.5, y: cy - radius * 1.5,
                    width: radius * 3, height: radius * 3
                )),
                with: .radialGradient(
                    Gradient(colors: [glowColor.opacity(0.025), glowColor.opacity(0)]),
                    center: CGPoint(x: cx, y: cy),
                    startRadius: radius * 0.3,
                    endRadius: radius * 1.5
                )
            )
        }
    }
}
