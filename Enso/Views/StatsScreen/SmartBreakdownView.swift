import SwiftUI

struct SmartBreakdownView: View {
    let result: SmartGoalResult
    let isDark: Bool

    var body: some View {
        let inkColor = EnsoTheme.adaptive(EnsoTheme.ink, EnsoTheme.inkDark, isDark: isDark)
        let midColor = EnsoTheme.adaptive(EnsoTheme.inkMid, EnsoTheme.inkMidDark, isDark: isDark)
        let whisperColor = EnsoTheme.adaptive(EnsoTheme.inkWhisper, EnsoTheme.inkWhisperDark, isDark: isDark)
        let vermillion = isDark ? EnsoTheme.vermillionDark : EnsoTheme.vermillion

        VStack(alignment: .leading, spacing: 0) {
            // Summary note
            HStack(spacing: 0) {
                Rectangle()
                    .fill(vermillion)
                    .frame(width: 2)
                Text(summaryText)
                    .font(EnsoTheme.labelFont(13))
                    .foregroundStyle(EnsoTheme.adaptive(EnsoTheme.inkWarm, EnsoTheme.inkWarmDark, isDark: isDark))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .background(
                isDark
                    ? EnsoTheme.vermillionDark.opacity(0.1)
                    : EnsoTheme.vermillion.opacity(0.12)
            )
            .clipShape(
                .rect(topLeadingRadius: 0, bottomLeadingRadius: 0,
                      bottomTrailingRadius: EnsoTheme.cornerRadius,
                      topTrailingRadius: EnsoTheme.cornerRadius)
            )

            // Breakdown rows
            VStack(spacing: 0) {
                ForEach(Array(result.adjustments.enumerated()), id: \.offset) { _, adj in
                    HStack {
                        Text(adj.reason)
                            .font(EnsoTheme.labelFont(12))
                            .foregroundStyle(midColor)
                        Spacer()
                        Text(adj.amount > 0 ? "+\(adj.amount) ml" : "+0 ml")
                            .font(EnsoTheme.settingFont(13))
                            .foregroundStyle(midColor)
                    }
                    .padding(.vertical, 7)

                    Divider().background(whisperColor)
                }

                // Total row
                HStack {
                    Text("Adjusted goal")
                        .font(EnsoTheme.labelFont(12))
                        .fontWeight(.medium)
                        .foregroundStyle(inkColor)
                    Spacer()
                    Text("\(result.adjustedGoal.formatted()) ml")
                        .font(EnsoTheme.settingFont(13))
                        .fontWeight(.medium)
                        .foregroundStyle(inkColor)
                }
                .padding(.top, 10)
            }
            .padding(.top, 12)
            .padding(.horizontal, 2)
        }
    }

    private var summaryText: String {
        result.totalAdjustment > 0
            ? "+\(result.totalAdjustment) ml — adjusted based on today's conditions"
            : "No adjustment needed — standard conditions"
    }
}
