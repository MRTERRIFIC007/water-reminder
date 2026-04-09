import SwiftUI

struct SettingsView: View {
    @Bindable var store: HydrationStore
    let isDark: Bool
    let healthKitAuthorized: Bool
    let weatherAuthorized: Bool
    let onClose: () -> Void
    let onReset: () -> Void

    var body: some View {
        let paperColor = EnsoTheme.adaptive(EnsoTheme.paper, EnsoTheme.paperDark, isDark: isDark)
        let inkColor = EnsoTheme.adaptive(EnsoTheme.ink, EnsoTheme.inkDark, isDark: isDark)
        let inkLight = EnsoTheme.adaptive(EnsoTheme.inkLight, EnsoTheme.inkLightDark, isDark: isDark)
        let fadedColor = EnsoTheme.adaptive(EnsoTheme.inkFaded, EnsoTheme.inkFadedDark, isDark: isDark)
        let ghostColor = EnsoTheme.adaptive(EnsoTheme.inkGhost, EnsoTheme.inkGhostDark, isDark: isDark)
        let whisperColor = EnsoTheme.adaptive(EnsoTheme.inkWhisper, EnsoTheme.inkWhisperDark, isDark: isDark)
        let syncGreen = isDark ? EnsoTheme.syncGreenDark : EnsoTheme.syncGreen

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(EnsoTheme.eyebrowFont(10))
                        .tracking(2.2)
                        .textCase(.uppercase)
                        .foregroundStyle(inkLight)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(inkColor)
                            .opacity(0.3)
                    }
                }
                .padding(.top, 56)
                .padding(.bottom, 20)

                Rectangle().fill(whisperColor).frame(height: 1).padding(.bottom, 24)

                // Hydration
                settingGroup(title: "hydration") {
                    settingRow(name: "Glass size") {
                        StepperControl(
                            value: $store.glassSize,
                            range: 50...1000,
                            step: 50,
                            format: { "\($0) ml" },
                            isDark: isDark
                        )
                    }
                    settingRow(name: "Daily goal") {
                        StepperControl(
                            value: $store.dailyBaseGoal,
                            range: 500...5000,
                            step: 250,
                            format: { "\($0.formatted()) ml" },
                            isDark: isDark
                        )
                    }
                }

                // Data sources
                settingGroup(title: "data sources") {
                    settingRow(name: "Apple Watch") {
                        Text(healthKitAuthorized ? "connected" : "not connected")
                            .font(EnsoTheme.labelFont(12))
                            .foregroundStyle(healthKitAuthorized ? syncGreen : fadedColor)
                            .tracking(0.5)
                    }
                    settingRow(name: "HealthKit") {
                        Text(healthKitAuthorized ? "authorized" : "not authorized")
                            .font(EnsoTheme.labelFont(12))
                            .foregroundStyle(healthKitAuthorized ? syncGreen : fadedColor)
                            .tracking(0.5)
                    }
                    settingRow(name: "Weather", showDivider: false) {
                        Text(weatherAuthorized ? "location active" : "no access")
                            .font(EnsoTheme.labelFont(12))
                            .foregroundStyle(weatherAuthorized ? syncGreen : fadedColor)
                            .tracking(0.5)
                    }
                    Text("Sleep, activity, heart rate, and workouts sync automatically from your Apple Watch")
                        .font(EnsoTheme.labelFont(11))
                        .foregroundStyle(fadedColor)
                        .lineSpacing(4)
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                }

                // Smart reminders
                settingGroup(title: "smart reminders") {
                    settingToggleRow(name: "Adapt to activity", isOn: $store.adaptToActivity)
                    settingToggleRow(name: "Adapt to weather", isOn: $store.adaptToWeather)
                    settingToggleRow(name: "Quiet during sleep", isOn: $store.quietDuringSleep, showDivider: false)
                }

                // Notifications
                settingGroup(title: "notifications") {
                    settingToggleRow(name: "Reminders", isOn: $store.notificationsEnabled)
                    settingToggleRow(name: "Haptics", isOn: $store.hapticsEnabled, showDivider: false)
                }

                // Reset
                Button(action: onReset) {
                    Text("reset today")
                        .font(EnsoTheme.labelFont(11))
                        .tracking(1.6)
                        .foregroundStyle(inkLight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: EnsoTheme.cornerRadius)
                                .stroke(ghostColor, lineWidth: 1)
                        )
                }
                .padding(.top, 40)
            }
            .padding(.horizontal, EnsoTheme.screenPadding)
            .padding(.bottom, 60)
        }
        .background(paperColor)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func settingGroup(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(EnsoTheme.eyebrowFont(9))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(EnsoTheme.adaptive(EnsoTheme.inkFaded, EnsoTheme.inkFadedDark, isDark: isDark))
                .padding(.bottom, 8)
            content()
        }
        .padding(.bottom, EnsoTheme.settingGroupSpacing)
    }

    @ViewBuilder
    private func settingRow(name: String, showDivider: Bool = true, @ViewBuilder trailing: () -> some View) -> some View {
        HStack {
            Text(name)
                .font(EnsoTheme.settingFont(15))
                .foregroundStyle(EnsoTheme.adaptive(EnsoTheme.ink, EnsoTheme.inkDark, isDark: isDark))
            Spacer()
            trailing()
        }
        .padding(.vertical, EnsoTheme.settingRowPadding)
        .overlay(alignment: .bottom) {
            if showDivider {
                Rectangle()
                    .fill(EnsoTheme.adaptive(EnsoTheme.inkWhisper, EnsoTheme.inkWhisperDark, isDark: isDark))
                    .frame(height: 1)
            }
        }
    }

    @ViewBuilder
    private func settingToggleRow(name: String, isOn: Binding<Bool>, showDivider: Bool = true) -> some View {
        settingRow(name: name, showDivider: showDivider) {
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(EnsoTheme.adaptive(EnsoTheme.ink, EnsoTheme.inkDark, isDark: isDark))
        }
    }
}

// MARK: - Stepper Control

struct StepperControl: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let format: (Int) -> String
    let isDark: Bool

    var body: some View {
        let inkLight = EnsoTheme.adaptive(EnsoTheme.inkLight, EnsoTheme.inkLightDark, isDark: isDark)
        let inkColor = EnsoTheme.adaptive(EnsoTheme.ink, EnsoTheme.inkDark, isDark: isDark)
        let ghostColor = EnsoTheme.adaptive(EnsoTheme.inkGhost, EnsoTheme.inkGhostDark, isDark: isDark)

        HStack(spacing: 14) {
            Button(action: { value = max(range.lowerBound, value - step) }) {
                Text("−")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(inkLight)
                    .frame(width: EnsoTheme.stepperButtonSize, height: EnsoTheme.stepperButtonSize)
                    .overlay(Circle().stroke(ghostColor, lineWidth: 1))
            }

            Text(format(value))
                .font(EnsoTheme.settingFont(16))
                .foregroundStyle(inkColor)
                .frame(minWidth: 56, alignment: .center)

            Button(action: { value = min(range.upperBound, value + step) }) {
                Text("+")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(inkLight)
                    .frame(width: EnsoTheme.stepperButtonSize, height: EnsoTheme.stepperButtonSize)
                    .overlay(Circle().stroke(ghostColor, lineWidth: 1))
            }
        }
    }
}
