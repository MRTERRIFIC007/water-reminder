import SwiftUI

struct ConditionsGridView: View {
    let cells: [(value: String, label: String)]
    let columns: Int
    let isDark: Bool

    var body: some View {
        let inkColor = EnsoTheme.adaptive(EnsoTheme.ink, EnsoTheme.inkDark, isDark: isDark)
        let fadedColor = EnsoTheme.adaptive(EnsoTheme.inkFaded, EnsoTheme.inkFadedDark, isDark: isDark)
        let whisperColor = EnsoTheme.adaptive(EnsoTheme.inkWhisper, EnsoTheme.inkWhisperDark, isDark: isDark)
        let paperColor = EnsoTheme.adaptive(EnsoTheme.paper, EnsoTheme.paperDark, isDark: isDark)

        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: columns),
            spacing: 1
        ) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                VStack(spacing: 6) {
                    Text(cell.value)
                        .font(EnsoTheme.valueFont(22))
                        .foregroundStyle(inkColor)

                    Text(cell.label)
                        .font(EnsoTheme.eyebrowFont(9))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(fadedColor)
                }
                .padding(.vertical, EnsoTheme.conditionCellPadding)
                .frame(maxWidth: .infinity)
                .background(paperColor)
            }
        }
        .background(whisperColor)
        .clipShape(RoundedRectangle(cornerRadius: EnsoTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: EnsoTheme.cornerRadius)
                .stroke(whisperColor, lineWidth: 1)
        )
    }
}
