import SwiftUI

@Observable
final class HydrationStore {
    // MARK: - User Settings
    var glassSize: Int = 250
    var dailyBaseGoal: Int = 2000
    var adaptToActivity: Bool = true
    var adaptToWeather: Bool = true
    var quietDuringSleep: Bool = true
    var notificationsEnabled: Bool = true
    var hapticsEnabled: Bool = true

    // MARK: - Today's State
    var glasses: Int = 0
    var weeklyGlasses: [Int] = [0, 0, 0, 0, 0, 0, 0]

    // MARK: - Dynamic Data
    var health = HealthData()
    var weather = WeatherData()

    // MARK: - Computed
    var todayMl: Int { glasses * glassSize }
    var maxGlasses: Int { max(Int(ceil(Double(dailyBaseGoal) / Double(glassSize))), 1) }
    var progress: Double { min(Double(glasses) / Double(maxGlasses), 1.0) }
    var isComplete: Bool { glasses >= maxGlasses }

    private let storeKey = "enso.store"
    private let dateKey = "enso.date"

    init() { load() }

    func logGlass() {
        guard glasses < maxGlasses + 2 else { return }
        glasses += 1
        weeklyGlasses[weeklyGlasses.count - 1] = glasses
        save()
    }

    func resetToday() {
        glasses = 0
        weeklyGlasses[weeklyGlasses.count - 1] = 0
        save()
    }

    private func save() {
        let data: [String: Any] = [
            "glasses": glasses,
            "glassSize": glassSize,
            "dailyBaseGoal": dailyBaseGoal,
            "weeklyGlasses": weeklyGlasses,
            "adaptToActivity": adaptToActivity,
            "adaptToWeather": adaptToWeather,
            "quietDuringSleep": quietDuringSleep,
            "notificationsEnabled": notificationsEnabled,
            "hapticsEnabled": hapticsEnabled,
        ]
        UserDefaults.standard.set(data, forKey: storeKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.dictionary(forKey: storeKey) else { return }
        glassSize = data["glassSize"] as? Int ?? 250
        dailyBaseGoal = data["dailyBaseGoal"] as? Int ?? 2000
        weeklyGlasses = data["weeklyGlasses"] as? [Int] ?? [0,0,0,0,0,0,0]
        adaptToActivity = data["adaptToActivity"] as? Bool ?? true
        adaptToWeather = data["adaptToWeather"] as? Bool ?? true
        quietDuringSleep = data["quietDuringSleep"] as? Bool ?? true
        notificationsEnabled = data["notificationsEnabled"] as? Bool ?? true
        hapticsEnabled = data["hapticsEnabled"] as? Bool ?? true

        let lastDate = UserDefaults.standard.string(forKey: dateKey) ?? ""
        let today = Self.todayString()
        if lastDate != today && !lastDate.isEmpty {
            weeklyGlasses.append(0)
            if weeklyGlasses.count > 7 { weeklyGlasses = Array(weeklyGlasses.suffix(7)) }
            glasses = 0
        } else {
            glasses = data["glasses"] as? Int ?? 0
        }
        UserDefaults.standard.set(today, forKey: dateKey)
    }

    private static func todayString() -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: Date())
    }
}
