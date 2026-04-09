import UserNotifications

enum NotificationManager {
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch { return false }
    }

    static func scheduleReminders(
        glasses: Int,
        maxGlasses: Int,
        wakeHour: Int = 7,
        sleepHour: Int = 23,
        quietDuringSleep: Bool = true
    ) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let remaining = maxGlasses - glasses
        guard remaining > 0 else { return }

        let now = Calendar.current.component(.hour, from: Date())
        let endHour = quietDuringSleep ? sleepHour : 24
        let hoursLeft = max(endHour - max(now, wakeHour), 1)
        let interval = max(hoursLeft * 60 / remaining, 30)

        for i in 0..<min(remaining, 8) {
            let content = UNMutableNotificationContent()
            content.title = "Enso"
            content.body = ["Time for water.", "A gentle reminder.", "Stay hydrated."][i % 3]
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: Double((i + 1) * interval * 60),
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "enso-\(i)",
                content: content,
                trigger: trigger
            )

            center.add(request)
        }
    }
}
