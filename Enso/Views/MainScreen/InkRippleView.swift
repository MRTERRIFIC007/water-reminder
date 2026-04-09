import SwiftUI

struct InkRippleView: View {
    let position: CGPoint
    let isDark: Bool
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0.7

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        (isDark ? EnsoTheme.inkGhostDark : EnsoTheme.inkGhost),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 30
                )
            )
            .frame(width: 60, height: 60)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(position)
            .onAppear {
                withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 1)) {
                    scale = 4
                    opacity = 0
                }
            }
    }
}
