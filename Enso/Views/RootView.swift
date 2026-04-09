import SwiftUI

struct PaperTextureView: View {
    let isDark: Bool

    var body: some View {
        Canvas { context, size in
            // Subtle horizontal fiber lines
            for y in stride(from: 0, through: size.height, by: 4) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(
                    path,
                    with: .color(isDark ? .white.opacity(0.008) : .black.opacity(0.008)),
                    lineWidth: 0.5
                )
            }
            for x in stride(from: 0, through: size.width, by: 6) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(
                    path,
                    with: .color(isDark ? .white.opacity(0.005) : .black.opacity(0.005)),
                    lineWidth: 0.5
                )
            }
        }
        .opacity(0.35)
    }
}

struct RootView: View {
    @State private var store = HydrationStore()
    @State private var healthKit = HealthKitManager()
    @State private var weatherManager = WeatherManager()
    @State private var showStats = false
    @State private var showSettings = false
    @State private var isDark = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let paperColor = EnsoTheme.adaptive(EnsoTheme.paper, EnsoTheme.paperDark, isDark: isDark)

        ZStack {
            paperColor.ignoresSafeArea()

            PaperTextureView(isDark: isDark)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Main screen
            MainView(
                store: store,
                isDark: isDark,
                onToggleTheme: { isDark.toggle() },
                onSwipeUp: { withAnimation(EnsoTheme.easeBrush) { showStats = true } }
            )
            .offset(y: showStats ? -UIScreen.main.bounds.height * 0.4 : 0)
            .scaleEffect(showStats ? 0.95 : 1)
            .opacity(showStats ? 0 : 1)
            .allowsHitTesting(!showStats)

            // Stats screen
            StatsView(
                store: store,
                isDark: isDark,
                onBack: { withAnimation(EnsoTheme.easeBrush) { showStats = false } },
                onOpenSettings: { withAnimation(EnsoTheme.easeBrush) { showSettings = true } }
            )
            .offset(y: showStats ? 0 : UIScreen.main.bounds.height)
            .allowsHitTesting(showStats)

            // Settings screen
            SettingsView(
                store: store,
                isDark: isDark,
                healthKitAuthorized: healthKit.isAuthorized,
                weatherAuthorized: weatherManager.isAuthorized,
                onClose: { withAnimation(EnsoTheme.easeBrush) { showSettings = false } },
                onReset: {
                    store.resetToday()
                    withAnimation(EnsoTheme.easeBrush) {
                        showSettings = false
                        showStats = false
                    }
                }
            )
            .offset(x: showSettings ? 0 : UIScreen.main.bounds.width)
            .allowsHitTesting(showSettings)
        }
        .preferredColorScheme(isDark ? .dark : .light)
        .task {
            await healthKit.requestAuthorization()
            weatherManager.requestAuthorization()
            await refreshData()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    healthKit.updateAuthorizationStatus()
                    await refreshData()
                }
            }
        }
    }

    private func refreshData() async {
        store.health = await healthKit.fetchTodayData()
        healthKit.updateAuthorizationFromData(store.health)
        await weatherManager.fetch()
        store.weather = weatherManager.data

        if store.notificationsEnabled {
            let _ = await NotificationManager.requestPermission()
            let wakeHour = Calendar.current.component(.hour, from: store.health.wakeTime ?? Date())
            NotificationManager.scheduleReminders(
                glasses: store.glasses,
                maxGlasses: store.maxGlasses,
                wakeHour: wakeHour,
                quietDuringSleep: store.quietDuringSleep
            )
        }
    }
}
