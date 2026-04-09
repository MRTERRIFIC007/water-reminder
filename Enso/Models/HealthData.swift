import Foundation

struct HealthData {
    var sleepHours: Double = 0
    var wakeTime: Date? = nil
    var bedTime: Date? = nil
    var steps: Int = 0
    var activeCalories: Int = 0
    var avgHeartRate: Int = 0
    var workout: WorkoutInfo? = nil
    var lastSync: Date = .distantPast

    struct WorkoutInfo {
        let type: String
        let durationMinutes: Int
    }
}

struct WeatherData {
    var currentTemp: Int = 0
    var highTemp: Int = 0
    var humidity: Int = 0
    var lastSync: Date = .distantPast
}
