import SwiftUI

struct SealView: View {
    let isVisible: Bool
    let isDark: Bool

    var body: some View {
        let color = isDark ? EnsoTheme.vermillionDark : EnsoTheme.vermillion

        Text("FULL")
            .font(EnsoTheme.valueFont(10))
            .fontWeight(.bold)
            .tracking(1)
            .foregroundStyle(color)
            .frame(width: EnsoTheme.sealSize, height: EnsoTheme.sealSize)
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 2)
            )
            .rotationEffect(.degrees(isVisible ? -8 : -15))
            .scaleEffect(isVisible ? 1 : 0)
            .opacity(isVisible ? 0.7 : 0)
            .animation(EnsoTheme.easeBrush, value: isVisible)
    }
}
