import SwiftUI

struct StatsView: View {
    @Bindable var store: HydrationStore
    let isDark: Bool
    let onBack: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        let paperColor = EnsoTheme.adaptive(EnsoTheme.paper, EnsoTheme.paperDark, isDark: isDark)
        let inkColor = EnsoTheme.adaptive(EnsoTheme.ink, EnsoTheme.inkDark, isDark: isDark)
        let inkLight = EnsoTheme.adaptive(EnsoTheme.inkLight, EnsoTheme.inkLightDark, isDark: isDark)
        let fadedColor = EnsoTheme.adaptive(EnsoTheme.inkFaded, EnsoTheme.inkFadedDark, isDark: isDark)
        let whisperColor = EnsoTheme.adaptive(EnsoTheme.inkWhisper, EnsoTheme.inkWhisperDark, isDark: isDark)
        let syncGreen = isDark ? EnsoTheme.syncGreenDark : EnsoTheme.syncGreen

        let smartResult = SmartGoalEngine.calculate(
            baseGoal: store.dailyBaseGoal,
            health: store.health,
            weather: store.weather,
            adaptToActivity: store.adaptToActivity,
            adaptToWeather: store.adaptToWeather
        )

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 10, weight: .light))
                            Text("return")
                                .font(EnsoTheme.labelFont(11))
                                .tracking(1.3)
                        }
                        .foregroundStyle(inkLight)
                    }
                    Spacer()
                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(inkColor)
                            .opacity(0.25)
                    }
                }
                .padding(.top, 56)
                .padding(.bottom, 20)

                // Divider
                Rectangle()
                    .fill(whisperColor)
                    .frame(height: 1)
                    .padding(.bottom, 36)

                // Today
                statBlock(title: "today") {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(store.todayMl.formatted())")
                            .font(EnsoTheme.heroFont(56))
                            .tracking(-1.5)
                        Text("ml")
                            .font(EnsoTheme.labelFont(18))
                            .foregroundStyle(EnsoTheme.adaptive(EnsoTheme.inkMid, EnsoTheme.inkMidDark, isDark: isDark))
                    }
                    .foregroundStyle(inkColor)

                    Text("of \(store.dailyBaseGoal.formatted()) ml")
                        .font(EnsoTheme.labelFont(13))
                        .foregroundStyle(inkLight)
                        .padding(.top, 6)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(whisperColor)
                                .frame(height: EnsoTheme.progressBarHeight)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(inkColor)
                                .frame(width: geo.size.width * store.progress, height: EnsoTheme.progressBarHeight)
                                .animation(EnsoTheme.easeBrush, value: store.progress)
                        }
                    }
                    .frame(height: EnsoTheme.progressBarHeight)
                    .padding(.top, 16)
                }

                // Weekly
                statBlock(title: "this week") {
                    WeeklyChartView(data: store.weeklyGlasses, isDark: isDark)
                }

                // Apple Watch data
                statBlock(title: nil) {
                    HStack(spacing: 6) {
                        Text("from apple watch")
                            .font(EnsoTheme.eyebrowFont(10))
                            .tracking(2.2)
                            .textCase(.uppercase)
                            .foregroundStyle(fadedColor)
                        Circle()
                            .fill(syncGreen)
                            .frame(width: 5, height: 5)
                    }

                    ConditionsGridView(
                        cells: [
                            (formatSleep(store.health.sleepHours), "sleep"),
                            (formatTime(store.health.wakeTime), "woke up"),
                            (formatSteps(store.health.steps), "steps"),
                            ("\(store.health.activeCalories)", "active cal"),
                            ("\(store.health.avgHeartRate)", "avg hr"),
                            (formatWorkout(store.health.workout), "workout"),
                        ],
                        columns: 3,
                        isDark: isDark
                    )
                    .padding(.top, 10)

                    Text(formatSyncTime(store.health.lastSync))
                        .font(EnsoTheme.labelFont(10))
                        .foregroundStyle(fadedColor)
                        .tracking(0.5)
                        .padding(.top, 10)
                }

                // Weather
                statBlock(title: "weather") {
                    ConditionsGridView(
                        cells: [
                            ("\(store.weather.currentTemp)°", "now"),
                            ("\(store.weather.highTemp)°", "high"),
                            ("\(store.weather.humidity)%", "humidity"),
                        ],
                        columns: 3,
                        isDark: isDark
                    )
                }

                // Smart adjustment
                statBlock(title: "smart adjustment") {
                    SmartBreakdownView(result: smartResult, isDark: isDark)
                }
            }
            .padding(.horizontal, EnsoTheme.screenPadding)
            .padding(.bottom, 60)
        }
        .background(paperColor)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func statBlock(title: String?, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Text(title)
                    .font(EnsoTheme.eyebrowFont(10))
                    .tracking(2.2)
                    .textCase(.uppercase)
                    .foregroundStyle(EnsoTheme.adaptive(EnsoTheme.inkFaded, EnsoTheme.inkFadedDark, isDark: isDark))
                    .padding(.bottom, 10)
            }
            content()
        }
        .padding(.bottom, EnsoTheme.statBlockSpacing)
    }

    private func formatSleep(_ hours: Double) -> String {
        guard hours > 0 else { return "—" }
        let totalMinutes = Int(hours * 60)
        let h = totalMinutes / 60
        let tenths = (totalMinutes % 60) * 10 / 60
        return "\(h).\(tenths)h"
    }

    private func formatTime(_ date: Date?) -> String {
        guard let date else { return "—" }
        let df = DateFormatter()
        df.dateFormat = "H:mm"
        return df.string(from: date)
    }

    private func formatSteps(_ steps: Int) -> String {
        steps >= 1000 ? String(format: "%.1fk", Double(steps) / 1000) : "\(steps)"
    }

    private func formatWorkout(_ w: HealthData.WorkoutInfo?) -> String {
        guard let w else { return "—" }
        return "\(w.type) \(w.durationMinutes)m"
    }

    private func formatSyncTime(_ date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 1 { return "synced just now" }
        return "synced \(minutes) min ago"
    }
}
