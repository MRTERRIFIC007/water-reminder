import Foundation

struct GoalAdjustment {
    let reason: String
    let amount: Int
}

struct SmartGoalResult {
    let baseGoal: Int
    let adjustments: [GoalAdjustment]
    var totalAdjustment: Int { adjustments.reduce(0) { $0 + $1.amount } }
    var adjustedGoal: Int { baseGoal + totalAdjustment }
}

enum SmartGoalEngine {
    static func calculate(
        baseGoal: Int,
        health: HealthData,
        weather: WeatherData,
        adaptToActivity: Bool,
        adaptToWeather: Bool
    ) -> SmartGoalResult {
        var adjustments: [GoalAdjustment] = []

        if adaptToWeather {
            let temp = weather.currentTemp
            if temp > 24 {
                let adj = min((temp - 24) * 50, 300)
                adjustments.append(.init(reason: "Warm weather (\(temp)°)", amount: adj))
            } else {
                adjustments.append(.init(reason: "Mild weather (\(temp)°)", amount: 0))
            }
        }

        if adaptToActivity {
            if health.steps > 4000 {
                let adj = min(((health.steps - 4000) / 1000) * 75, 375)
                let label = health.steps >= 1000
                    ? String(format: "%.1fk", Double(health.steps) / 1000)
                    : "\(health.steps)"
                adjustments.append(.init(reason: "Active day (\(label) steps)", amount: adj))
            } else {
                adjustments.append(.init(reason: "Low activity", amount: 0))
            }

            if let w = health.workout {
                let adj = min(w.durationMinutes * 8, 250)
                adjustments.append(.init(reason: "\(w.type) (\(w.durationMinutes)m)", amount: adj))
            }

            if health.sleepHours > 0 && health.sleepHours < 6 {
                adjustments.append(.init(reason: "Short sleep (\(String(format: "%.1f", health.sleepHours))h)", amount: 100))
            } else if health.sleepHours >= 6 {
                adjustments.append(.init(reason: "Good sleep (\(String(format: "%.1f", health.sleepHours))h)", amount: 0))
            }
        }

        return SmartGoalResult(baseGoal: baseGoal, adjustments: adjustments)
    }
}
