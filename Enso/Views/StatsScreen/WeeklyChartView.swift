import SwiftUI

struct WeeklyChartView: View {
    let data: [Int]
    let isDark: Bool

    private let days = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        let maxVal = max(data.max() ?? 1, 1)
        let inkColor = EnsoTheme.adaptive(EnsoTheme.ink, EnsoTheme.inkDark, isDark: isDark)
        let fadedColor = EnsoTheme.adaptive(EnsoTheme.inkFaded, EnsoTheme.inkFadedDark, isDark: isDark)

        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                let isToday = index == data.count - 1
                let height = max(CGFloat(value) / CGFloat(maxVal) * 70, 1)

                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(inkColor)
                        .frame(maxWidth: 20, minHeight: 1)
                        .frame(height: height)
                        .opacity(isToday ? 0.75 : (value > 0 ? 0.2 : 0.1))

                    Text(days[index])
                        .font(EnsoTheme.labelFont(10))
                        .foregroundStyle(fadedColor)
                        .tracking(0.5)
                }
            }
        }
        .frame(height: EnsoTheme.weekChartHeight)
    }
}
