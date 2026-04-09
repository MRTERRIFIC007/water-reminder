# Enso — Water Reminder SwiftUI Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a minimal zen water reminder iPhone app with an enso brush circle UI, HealthKit/Apple Watch integration, and smart goal adjustment.

**Architecture:** Single-target iOS app using SwiftUI with MVVM. Canvas API for enso rendering, HealthKit for Apple Watch data, WeatherKit for weather, UserDefaults for persistence. All local, no cloud.

**Tech Stack:** Swift 5.9+, SwiftUI, Canvas, HealthKit, WeatherKit, CoreLocation, UserNotifications, iOS 17+

**Design Reference:**
- Interactive mockup: `index.html` (open in browser)
- Design spec sheet: `docs/mockup-screenshots/reference-sheet.html` (colors, typography, spacing, animations)
- Design doc: `docs/plans/2026-03-11-enso-design.md`

---

## File Structure

```
Enso/
├── EnsoApp.swift                    # App entry point
├── Info.plist                       # HealthKit + Location usage descriptions
├── Enso.entitlements               # HealthKit entitlement
├── Theme/
│   └── EnsoTheme.swift             # Colors, fonts, spacing constants
├── Models/
│   ├── HydrationStore.swift        # @Observable — glasses, goal, settings, persistence
│   └── HealthData.swift            # Struct for Apple Watch + weather data
├── Services/
│   ├── HealthKitManager.swift      # HealthKit queries (sleep, steps, HR, workouts, calories)
│   ├── WeatherManager.swift        # WeatherKit + CoreLocation
│   ├── SmartGoalEngine.swift       # Goal adjustment algorithm
│   └── NotificationManager.swift   # Local notification scheduling
├── Views/
│   ├── RootView.swift              # Navigation container — manages screen transitions
│   ├── MainScreen/
│   │   ├── MainView.swift          # Enso screen layout
│   │   ├── EnsoCanvasView.swift    # Canvas brush stroke rendering
│   │   ├── InkRippleView.swift     # Tap ripple animation
│   │   └── SealView.swift          # Completion hanko seal
│   ├── StatsScreen/
│   │   ├── StatsView.swift         # Stats scroll view layout
│   │   ├── WeeklyChartView.swift   # 7-day bar chart
│   │   ├── ConditionsGridView.swift # Apple Watch + weather grids
│   │   └── SmartBreakdownView.swift # Goal adjustment breakdown
│   └── SettingsScreen/
│       └── SettingsView.swift      # Settings form
```

---

### Task 1: Create Xcode Project Skeleton

**Files:**
- Create: `Enso/EnsoApp.swift`
- Create: `Enso/Info.plist`
- Create: `Enso.xcodeproj` (via xcodegen or manual)

**Step 1: Install xcodegen if needed**

Run: `brew list xcodegen || brew install xcodegen`

**Step 2: Create project spec**

Create `project.yml` at project root:

```yaml
name: Enso
options:
  bundleIdPrefix: com.personal
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "15.0"
settings:
  base:
    DEVELOPMENT_TEAM: ""
    CODE_SIGN_STYLE: Automatic
    SWIFT_VERSION: "5.9"
targets:
  Enso:
    type: application
    platform: iOS
    sources:
      - path: Enso
    settings:
      base:
        INFOPLIST_FILE: Enso/Info.plist
        PRODUCT_BUNDLE_IDENTIFIER: com.personal.enso
    entitlements:
      path: Enso/Enso.entitlements
```

**Step 3: Create directory structure**

```bash
mkdir -p Enso/{Theme,Models,Services,Views/{MainScreen,StatsScreen,SettingsScreen}}
```

**Step 4: Create EnsoApp.swift**

```swift
import SwiftUI

@main
struct EnsoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(nil) // respect system, or manual toggle
        }
    }
}
```

**Step 5: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSHealthShareUsageDescription</key>
    <string>Enso reads your sleep, steps, heart rate, and workout data to adjust your water goal.</string>
    <key>NSHealthUpdateUsageDescription</key>
    <string>Enso records your water intake to HealthKit.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Enso uses your location to check weather and adjust your water goal.</string>
</dict>
</plist>
```

**Step 6: Create entitlements**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.healthkit</key>
    <true/>
    <key>com.apple.developer.healthkit.access</key>
    <array/>
    <key>com.apple.developer.weatherkit</key>
    <true/>
</dict>
</plist>
```

**Step 7: Generate project and verify**

Run: `xcodegen generate`
Run: `xcodebuild -project Enso.xcodeproj -scheme Enso -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | tail -5`

**Step 8: Commit**

```bash
git init && git add -A && git commit -m "feat: scaffold Enso Xcode project"
```

---

### Task 2: Theme System (EnsoTheme.swift)

**Files:**
- Create: `Enso/Theme/EnsoTheme.swift`

All colors, fonts, and spacing constants extracted from the mockup. This is the source of truth for every view.

**Step 1: Create theme file**

```swift
import SwiftUI

enum EnsoTheme {
    // MARK: - Colors (Light)
    // See: docs/mockup-screenshots/reference-sheet.html

    static let paper       = Color(hex: "F2EDE3")
    static let paperGrain  = Color(hex: "EDE7DB")
    static let paperShadow = Color(hex: "E4DDD0")

    static let ink         = Color(hex: "2A2826")
    static let inkWarm     = Color(hex: "3D3835")
    static let inkMid      = Color(hex: "7A756E")
    static let inkLight    = Color(hex: "A8A29A")
    static let inkFaded    = Color(hex: "C8C2B8")
    static let inkGhost    = Color(hex: "DBD6CC")
    static let inkWhisper  = Color(hex: "E8E3D9")

    static let vermillion     = Color(hex: "C4453C")
    static let vermillionSoft = Color(hex: "C4453C").opacity(0.12)

    // MARK: - Colors (Dark)

    static let paperDark       = Color(hex: "161514")
    static let paperGrainDark  = Color(hex: "1C1B19")

    static let inkDark         = Color(hex: "E4DFD6")
    static let inkWarmDark     = Color(hex: "D4CFC5")
    static let inkMidDark      = Color(hex: "8A857D")
    static let inkLightDark    = Color(hex: "5A5650")
    static let inkFadedDark    = Color(hex: "3D3A36")
    static let inkGhostDark    = Color(hex: "2A2825")
    static let inkWhisperDark  = Color(hex: "222120")

    static let vermillionDark  = Color(hex: "D4615A")

    static let syncGreen      = Color(hex: "6BA368")
    static let syncGreenDark  = Color(hex: "7CB87A")

    // MARK: - Adaptive Colors

    static func adaptive(_ light: Color, _ dark: Color, isDark: Bool) -> Color {
        isDark ? dark : light
    }

    // MARK: - Typography
    // Shippori Mincho: hero numbers, values, setting names, stepper values
    // Cormorant Garamond: labels, subtitles, eyebrows, back buttons

    // Note: These Google Fonts must be bundled in the app.
    // Download .ttf files and add to Xcode target.
    // Fallback to Georgia serif if fonts not available.

    static func heroFont(_ size: CGFloat = 56) -> Font {
        .custom("ShipporiMincho-Regular", size: size)
    }

    static func valueFont(_ size: CGFloat = 22) -> Font {
        .custom("ShipporiMincho-Regular", size: size)
    }

    static func settingFont(_ size: CGFloat = 15) -> Font {
        .custom("ShipporiMincho-Regular", size: size)
    }

    static func labelFont(_ size: CGFloat = 12) -> Font {
        .custom("CormorantGaramond-LightItalic", size: size)
    }

    static func eyebrowFont(_ size: CGFloat = 10) -> Font {
        .custom("CormorantGaramond-LightItalic", size: size)
    }

    // MARK: - Spacing (from reference-sheet.html)

    static let screenPadding: CGFloat = 28
    static let statBlockSpacing: CGFloat = 44
    static let sectionDivider: CGFloat = 1
    static let settingGroupSpacing: CGFloat = 32
    static let settingRowPadding: CGFloat = 16
    static let conditionCellPadding: CGFloat = 18
    static let cornerRadius: CGFloat = 16
    static let progressBarHeight: CGFloat = 3
    static let weekChartHeight: CGFloat = 100

    // MARK: - Enso Canvas
    static let ensoSize: CGFloat = 260
    static let ensoCanvasScale: CGFloat = 2 // @2x rendering
    static let ensoRadius: CGFloat = 0.37   // fraction of canvas width
    static let ensoStartAngle: Double = -0.55 * .pi

    // MARK: - Animation Curves
    static let easeBrush = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.7)
    static let easeInk   = Animation.timingCurve(0.33, 0, 0.2, 1, duration: 0.6)

    // MARK: - Component Sizes
    static let sealSize: CGFloat = 52
    static let themeButtonSize: CGFloat = 28
    static let stepperButtonSize: CGFloat = 30
    static let toggleWidth: CGFloat = 42
    static let toggleHeight: CGFloat = 24
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}
```

**Step 2: Download and bundle fonts**

Download from Google Fonts:
- ShipporiMincho-Regular.ttf
- ShipporiMincho-Medium.ttf
- ShipporiMincho-Bold.ttf
- CormorantGaramond-Light.ttf
- CormorantGaramond-LightItalic.ttf
- CormorantGaramond-Regular.ttf

Place in `Enso/Resources/Fonts/` and add to Info.plist:

```xml
<key>UIAppFonts</key>
<array>
    <string>ShipporiMincho-Regular.ttf</string>
    <string>ShipporiMincho-Medium.ttf</string>
    <string>ShipporiMincho-Bold.ttf</string>
    <string>CormorantGaramond-Light.ttf</string>
    <string>CormorantGaramond-LightItalic.ttf</string>
    <string>CormorantGaramond-Regular.ttf</string>
</array>
```

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add theme system with all colors, fonts, spacing"
```

---

### Task 3: Data Models (HydrationStore + HealthData)

**Files:**
- Create: `Enso/Models/HydrationStore.swift`
- Create: `Enso/Models/HealthData.swift`

**Step 1: Create HealthData model**

```swift
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
```

**Step 2: Create HydrationStore**

```swift
import SwiftUI

@Observable
final class HydrationStore {
    // MARK: - User Settings
    var glassSize: Int = 250           // ml
    var dailyBaseGoal: Int = 2000      // ml
    var adaptToActivity: Bool = true
    var adaptToWeather: Bool = true
    var quietDuringSleep: Bool = true
    var notificationsEnabled: Bool = true
    var hapticsEnabled: Bool = true

    // MARK: - Today's State
    var glasses: Int = 0
    var weeklyGlasses: [Int] = [0, 0, 0, 0, 0, 0, 0] // Mon-Sun

    // MARK: - Dynamic Data
    var health = HealthData()
    var weather = WeatherData()

    // MARK: - Computed
    var todayMl: Int { glasses * glassSize }
    var maxGlasses: Int { max(Int(ceil(Double(dailyBaseGoal) / Double(glassSize))), 1) }
    var progress: Double { min(Double(glasses) / Double(maxGlasses), 1.0) }
    var isComplete: Bool { glasses >= maxGlasses }

    // MARK: - Persistence Keys
    private let storeKey = "enso.store"
    private let dateKey = "enso.date"

    init() {
        load()
    }

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

    // MARK: - Persistence (UserDefaults)

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

        // Check for new day
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
```

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add HydrationStore and HealthData models"
```

---

### Task 4: Smart Goal Engine

**Files:**
- Create: `Enso/Services/SmartGoalEngine.swift`

**Step 1: Create the engine**

```swift
import Foundation

struct GoalAdjustment {
    let reason: String
    let amount: Int  // ml to add
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

        // Weather: +50ml per degree above 24C (max +300)
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
            // Steps: +75ml per 1000 steps above 4000 (max +375)
            if health.steps > 4000 {
                let adj = min(((health.steps - 4000) / 1000) * 75, 375)
                let label = health.steps >= 1000
                    ? String(format: "%.1fk", Double(health.steps) / 1000)
                    : "\(health.steps)"
                adjustments.append(.init(reason: "Active day (\(label) steps)", amount: adj))
            } else {
                adjustments.append(.init(reason: "Low activity", amount: 0))
            }

            // Workout: +8ml per minute (max +250)
            if let w = health.workout {
                let adj = min(w.durationMinutes * 8, 250)
                adjustments.append(.init(reason: "\(w.type) (\(w.durationMinutes)m)", amount: adj))
            }

            // Poor sleep (<6h): +100ml
            if health.sleepHours > 0 && health.sleepHours < 6 {
                adjustments.append(.init(reason: "Short sleep (\(String(format: "%.1f", health.sleepHours))h)", amount: 100))
            } else if health.sleepHours >= 6 {
                adjustments.append(.init(reason: "Good sleep (\(String(format: "%.1f", health.sleepHours))h)", amount: 0))
            }
        }

        return SmartGoalResult(baseGoal: baseGoal, adjustments: adjustments)
    }
}
```

**Step 2: Commit**

```bash
git add -A && git commit -m "feat: add smart goal adjustment engine"
```

---

### Task 5: HealthKit Manager

**Files:**
- Create: `Enso/Services/HealthKitManager.swift`

**Step 1: Create HealthKit service**

```swift
import HealthKit

@Observable
final class HealthKitManager {
    private let store = HKHealthStore()
    var isAuthorized = false

    private let readTypes: Set<HKObjectType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.heartRate),
        HKCategoryType(.sleepAnalysis),
        HKObjectType.workoutType(),
    ]

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
        } catch {
            print("HealthKit auth failed: \(error)")
        }
    }

    func fetchTodayData() async -> HealthData {
        var data = HealthData()
        data.lastSync = Date()

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        async let steps = querySum(.stepCount, from: startOfDay, to: now)
        async let calories = querySum(.activeEnergyBurned, from: startOfDay, to: now)
        async let heartRate = queryAverage(.heartRate, from: startOfDay, to: now)
        async let sleep = querySleep(for: now)
        async let workout = queryLatestWorkout(from: startOfDay, to: now)

        data.steps = Int(await steps)
        data.activeCalories = Int(await calories)
        data.avgHeartRate = Int(await heartRate)

        let sleepResult = await sleep
        data.sleepHours = sleepResult.hours
        data.wakeTime = sleepResult.wakeTime
        data.bedTime = sleepResult.bedTime

        data.workout = await workout

        return data
    }

    // MARK: - Query Helpers

    private func querySum(_ type: HKQuantityTypeIdentifier, from: Date, to: Date) async -> Double {
        let quantityType = HKQuantityType(type)
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .init(quantityType: quantityType, predicate: predicate),
            options: .cumulativeSum
        )
        do {
            let result = try await descriptor.result(for: store)
            let unit: HKUnit = type == .activeEnergyBurned ? .kilocalorie() : .count()
            return result?.sumQuantity()?.doubleValue(for: unit) ?? 0
        } catch { return 0 }
    }

    private func queryAverage(_ type: HKQuantityTypeIdentifier, from: Date, to: Date) async -> Double {
        let quantityType = HKQuantityType(type)
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .init(quantityType: quantityType, predicate: predicate),
            options: .discreteAverage
        )
        do {
            let result = try await descriptor.result(for: store)
            let unit: HKUnit = type == .heartRate
                ? HKUnit.count().unitDivided(by: .minute())
                : .count()
            return result?.averageQuantity()?.doubleValue(for: unit) ?? 0
        } catch { return 0 }
    }

    private func querySleep(for date: Date) async -> (hours: Double, wakeTime: Date?, bedTime: Date?) {
        let calendar = Calendar.current
        // Look back to yesterday 6pm for sleep start
        let sleepWindowStart = calendar.date(byAdding: .hour, value: -18, to: calendar.startOfDay(for: date))!
        let predicate = HKQuery.predicateForSamples(withStart: sleepWindowStart, end: date)
        let sleepType = HKCategoryType(.sleepAnalysis)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )

        do {
            let samples = try await descriptor.result(for: store)
            let asleepSamples = samples.filter { sample in
                let val = HKCategoryValueSleepAnalysis(rawValue: sample.value)
                return val == .asleepCore || val == .asleepDeep || val == .asleepREM
            }

            guard !asleepSamples.isEmpty else { return (0, nil, nil) }

            let totalSeconds = asleepSamples.reduce(0.0) { sum, sample in
                sum + sample.endDate.timeIntervalSince(sample.startDate)
            }

            let bedTime = asleepSamples.first?.startDate
            let wakeTime = asleepSamples.last?.endDate

            return (totalSeconds / 3600, wakeTime, bedTime)
        } catch { return (0, nil, nil) }
    }

    private func queryLatestWorkout(from: Date, to: Date) async -> HealthData.WorkoutInfo? {
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )

        do {
            let workouts = try await descriptor.result(for: store)
            guard let w = workouts.first else { return nil }
            let name = w.workoutActivityType.commonName
            let minutes = Int(w.duration / 60)
            return .init(type: name, durationMinutes: minutes)
        } catch { return nil }
    }
}

// MARK: - Workout Activity Name

extension HKWorkoutActivityType {
    var commonName: String {
        switch self {
        case .running: return "Run"
        case .walking: return "Walk"
        case .cycling: return "Cycle"
        case .swimming: return "Swim"
        case .yoga: return "Yoga"
        case .hiking: return "Hike"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "Strength"
        case .highIntensityIntervalTraining: return "HIIT"
        default: return "Workout"
        }
    }
}
```

**Step 2: Commit**

```bash
git add -A && git commit -m "feat: add HealthKit manager for Apple Watch data"
```

---

### Task 6: Weather Manager

**Files:**
- Create: `Enso/Services/WeatherManager.swift`

**Step 1: Create weather service**

```swift
import WeatherKit
import CoreLocation

@Observable
final class WeatherManager: NSObject, CLLocationManagerDelegate {
    private let weatherService = WeatherService.shared
    private let locationManager = CLLocationManager()
    private var location: CLLocation?

    var data = WeatherData()
    var isAuthorized = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func fetch() async {
        guard let loc = location else { return }
        do {
            let weather = try await weatherService.weather(for: loc)
            data.currentTemp = Int(weather.currentWeather.temperature.converted(to: .celsius).value)
            data.humidity = Int(weather.currentWeather.humidity * 100)

            if let todayForecast = weather.dailyForecast.first {
                data.highTemp = Int(todayForecast.highTemperature.converted(to: .celsius).value)
            }
            data.lastSync = Date()
        } catch {
            print("Weather fetch failed: \(error)")
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            manager.requestLocation()
        default:
            isAuthorized = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}
```

**Step 2: Commit**

```bash
git add -A && git commit -m "feat: add WeatherKit manager with CoreLocation"
```

---

### Task 7: Notification Manager

**Files:**
- Create: `Enso/Services/NotificationManager.swift`

**Step 1: Create notification service**

```swift
import UserNotifications

enum NotificationManager {
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch { return false }
    }

    /// Schedule reminders spread across wake hours
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
        let interval = max(hoursLeft * 60 / remaining, 30) // minutes, minimum 30

        for i in 0..<min(remaining, 8) {
            let content = UNMutableNotificationContent()
            content.title = "Ensō"
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
```

**Step 2: Commit**

```bash
git add -A && git commit -m "feat: add notification manager for smart reminders"
```

---

### Task 8: RootView — Navigation Container

**Files:**
- Create: `Enso/Views/RootView.swift`

**Step 1: Create root navigation**

This manages the three screens and their transitions matching the mockup:
- Main -> Stats: swipe up / slide up
- Stats -> Settings: slide from right
- Stats -> Main: slide back down

```swift
import SwiftUI

struct RootView: View {
    @State private var store = HydrationStore()
    @State private var healthKit = HealthKitManager()
    @State private var weatherManager = WeatherManager()
    @State private var showStats = false
    @State private var showSettings = false
    @State private var isDark = false

    var body: some View {
        let paperColor = EnsoTheme.adaptive(EnsoTheme.paper, EnsoTheme.paperDark, isDark: isDark)

        ZStack {
            paperColor.ignoresSafeArea()

            // Paper texture overlay
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
    }

    private func refreshData() async {
        store.health = await healthKit.fetchTodayData()
        await weatherManager.fetch()
        store.weather = weatherManager.data

        if store.notificationsEnabled {
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
```

**Step 2: Create paper texture view**

```swift
// Add to bottom of RootView.swift or separate file

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
            // Subtle vertical fiber lines
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
```

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add RootView navigation container with screen transitions"
```

---

### Task 9: Enso Canvas — Brush Stroke Rendering

**Files:**
- Create: `Enso/Views/MainScreen/EnsoCanvasView.swift`

This is the heart of the app. Port the JS canvas rendering from `index.html` to SwiftUI Canvas.

**Step 1: Create the canvas view**

```swift
import SwiftUI

struct EnsoCanvasView: View {
    let progress: Double  // 0...1
    let isDark: Bool

    // Exactly match mockup: reference-sheet.html "Enso Brush Stroke" section
    private let canvasSize: CGFloat = EnsoTheme.ensoSize
    private let scale: CGFloat = EnsoTheme.ensoCanvasScale

    var body: some View {
        Canvas { context, size in
            drawEnso(context: context, size: size, progress: progress)
        }
        .frame(width: canvasSize, height: canvasSize)
    }

    private func drawEnso(context: GraphicsContext, size: CGSize, progress p: Double) {
        guard p > 0.005 else { return }

        let w = size.width
        let h = size.height
        let cx = w / 2
        let cy = h / 2
        let radius = w * EnsoTheme.ensoRadius

        // Arc extent: 12% at 0 progress -> 94% at full
        let arcExtent: Double = p < 1
            ? (0.12 + p * 0.83) * .pi * 2
            : .pi * 2 * 0.94
        let startAngle = EnsoTheme.ensoStartAngle

        let baseWidth: CGFloat = 5 + CGFloat(p) * 18
        let baseAlpha: Double = 0.06 + p * 0.88

        let steps = 300

        // Deterministic noise function
        func noise(_ i: Int) -> Double {
            let x = sin(Double(i) * 127.1 + 42) * 43758.5453
            return x - floor(x)
        }

        // Draw each segment of the brush stroke
        for i in 0..<steps {
            let t = Double(i) / Double(steps)
            let tNext = Double(i + 1) / Double(steps)

            let angle = startAngle + t * arcExtent
            let angleNext = startAngle + tNext * arcExtent

            // Organic wobble
            let w1 = sin(t * 53.7) * 1.8
            let w2 = cos(t * 37.3) * 1.1
            let w3 = (noise(i) - 0.5) * 1.4
            let wobble = CGFloat(w1 + w2 + w3)

            // Brush pressure profile
            let pressure: Double
            if t < 0.06 {
                pressure = t / 0.06                          // attack
            } else if t < 0.25 {
                pressure = 1.0 - (t - 0.06) * 1.2           // ease off
            } else if t < 0.7 {
                pressure = 0.55 + sin((t - 0.25) * 3.5) * 0.15 // sustain
            } else if t < 0.88 {
                pressure = 0.55 + (t - 0.7) * 2.5           // press down
            } else {
                pressure = max(0, 1.0 - (t - 0.88) * 8.3)   // dry brush lift
            }

            let currentWidth = baseWidth * CGFloat(0.4 + pressure * 0.6)

            // Alpha variation along stroke
            let alphaVar = 0.9 + sin(t * 19) * 0.1
            let alpha = min(baseAlpha * (0.8 + pressure * 0.2) * alphaVar, 0.95)

            let r1 = radius + wobble
            let r2 = radius + wobble
            let x1 = cx + cos(angle) * r1
            let y1 = cy + sin(angle) * r1
            let x2 = cx + cos(angleNext) * r2
            let y2 = cy + sin(angleNext) * r2

            var path = Path()
            path.move(to: CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x2, y: y2))

            let inkColor = isDark
                ? Color(red: 228/255, green: 223/255, blue: 214/255).opacity(alpha)
                : Color(red: 38/255, green: 36/255, blue: 34/255).opacity(alpha)

            context.stroke(
                path,
                with: .color(inkColor),
                style: StrokeStyle(lineWidth: currentWidth, lineCap: .round)
            )
        }

        // Ink splatter dots
        if p > 0.15 {
            let splatCount = Int(p * 12)
            for i in 0..<splatCount {
                let t = noise(i + 1000)
                let angle = startAngle + t * arcExtent
                let offset = CGFloat(noise(i + 2000) - 0.5) * baseWidth * 2.5
                let perpAngle = angle + .pi / 2
                let sx = cx + cos(angle) * radius + cos(perpAngle) * offset
                let sy = cy + sin(angle) * radius + sin(perpAngle) * offset
                let sr = CGFloat(noise(i + 3000)) * 1.2 + 0.2

                let splatAlpha = baseAlpha * 0.25 * noise(i + 4000)
                let splatColor = isDark
                    ? Color(red: 228/255, green: 223/255, blue: 214/255).opacity(splatAlpha)
                    : Color(red: 38/255, green: 36/255, blue: 34/255).opacity(splatAlpha)

                context.fill(
                    Path(ellipseIn: CGRect(x: sx - sr, y: sy - sr, width: sr * 2, height: sr * 2)),
                    with: .color(splatColor)
                )
            }
        }

        // Completion radial glow
        if p >= 1 {
            let glowColor = isDark
                ? Color(red: 228/255, green: 223/255, blue: 214/255)
                : Color(red: 38/255, green: 36/255, blue: 34/255)
            let center = CGPoint(x: cx, y: cy)

            context.fill(
                Path(ellipseIn: CGRect(
                    x: cx - radius * 1.5, y: cy - radius * 1.5,
                    width: radius * 3, height: radius * 3
                )),
                with: .radialGradient(
                    Gradient(colors: [glowColor.opacity(0.025), glowColor.opacity(0)]),
                    center: center,
                    startRadius: radius * 0.3,
                    endRadius: radius * 1.5
                )
            )
        }
    }
}
```

**Step 2: Commit**

```bash
git add -A && git commit -m "feat: add enso canvas brush stroke rendering"
```

---

### Task 10: Main Screen View

**Files:**
- Create: `Enso/Views/MainScreen/MainView.swift`
- Create: `Enso/Views/MainScreen/InkRippleView.swift`
- Create: `Enso/Views/MainScreen/SealView.swift`

**Step 1: Create InkRippleView**

```swift
import SwiftUI

struct InkRippleView: View {
    let position: CGPoint
    let isDark: Bool
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0.7

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        (isDark ? EnsoTheme.inkGhostDark : EnsoTheme.inkGhost),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 30
                )
            )
            .frame(width: 60, height: 60)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(position)
            .onAppear {
                withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 1)) {
                    scale = 4
                    opacity = 0
                }
            }
    }
}
```

**Step 2: Create SealView**

```swift
import SwiftUI

struct SealView: View {
    let isVisible: Bool
    let isDark: Bool

    var body: some View {
        let color = isDark ? EnsoTheme.vermillionDark : EnsoTheme.vermillion

        Text("FULL")
            .font(EnsoTheme.valueFont(10))
            .fontWeight(.bold)
            .tracking(1)
            .foregroundStyle(color)
            .frame(width: EnsoTheme.sealSize, height: EnsoTheme.sealSize)
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 2)
            )
            .rotationEffect(.degrees(isVisible ? -8 : -15))
            .scaleEffect(isVisible ? 1 : 0)
            .opacity(isVisible ? 0.7 : 0)
            .animation(EnsoTheme.easeBrush, value: isVisible)
    }
}
```

**Step 3: Create MainView**

```swift
import SwiftUI

struct MainView: View {
    @Bindable var store: HydrationStore
    let isDark: Bool
    let onToggleTheme: () -> Void
    let onSwipeUp: () -> Void

    @State private var animatedProgress: Double = 0
    @State private var ripples: [(id: UUID, position: CGPoint)] = []
    @State private var showInkWash = false
    @State private var toastText: String? = nil

    var body: some View {
        let inkColor = EnsoTheme.adaptive(EnsoTheme.ink, EnsoTheme.inkDark, isDark: isDark)
        let inkLight = EnsoTheme.adaptive(EnsoTheme.inkLight, EnsoTheme.inkLightDark, isDark: isDark)
        let inkFaded = EnsoTheme.adaptive(EnsoTheme.inkFaded, EnsoTheme.inkFadedDark, isDark: isDark)
        let paperColor = EnsoTheme.adaptive(EnsoTheme.paper, EnsoTheme.paperDark, isDark: isDark)

        ZStack {
            // Ink wash (completion effect)
            if showInkWash {
                RadialGradient(
                    colors: [inkColor.opacity(0.06), .clear],
                    center: UnitPoint(x: 0.5, y: 0.42),
                    startRadius: 0,
                    endRadius: 300
                )
                .ignoresSafeArea()
                .transition(.opacity)
            }

            VStack(spacing: 0) {
                Spacer()

                // The Enso
                ZStack {
                    EnsoCanvasView(progress: animatedProgress, isDark: isDark)

                    // Ink ripples
                    ForEach(ripples, id: \.id) { ripple in
                        InkRippleView(position: ripple.position, isDark: isDark)
                    }

                    // Completion seal
                    SealView(isVisible: store.isComplete, isDark: isDark)
                }
                .frame(width: EnsoTheme.ensoSize, height: EnsoTheme.ensoSize)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    logWater(at: location)
                }
                .offset(y: -30)

                // Progress label
                if store.glasses > 0 {
                    VStack(spacing: 6) {
                        Text("\(store.todayMl)")
                            .font(EnsoTheme.heroFont(32))
                            .foregroundStyle(inkColor)
                            .tracking(-0.5)

                        Text("of \(store.dailyBaseGoal.formatted()) ml")
                            .font(EnsoTheme.labelFont(12))
                            .foregroundStyle(inkLight)
                            .tracking(0.7)
                    }
                    .padding(.top, 32)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 6)),
                        removal: .opacity
                    ))
                }

                Spacer()
            }

            // Theme toggle (top right)
            VStack {
                HStack {
                    Spacer()
                    Button(action: onToggleTheme) {
                        Image(systemName: isDark ? "moon" : "sun.max")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(inkColor)
                    }
                    .frame(width: EnsoTheme.themeButtonSize, height: EnsoTheme.themeButtonSize)
                    .opacity(0.2)
                    .padding(.top, 58)
                    .padding(.trailing, 24)
                }
                Spacer()
            }

            // Toast
            if let toast = toastText {
                VStack {
                    Text(toast)
                        .font(EnsoTheme.labelFont(13))
                        .foregroundStyle(EnsoTheme.adaptive(EnsoTheme.inkMid, EnsoTheme.inkMidDark, isDark: isDark))
                        .tracking(1)
                        .padding(.top, 68)
                    Spacer()
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: -12)),
                    removal: .opacity
                ))
            }

            // Swipe cue (bottom)
            VStack {
                Spacer()
                VStack(spacing: 6) {
                    Rectangle()
                        .fill(inkLight)
                        .frame(width: 28, height: 1)
                    Text("details")
                        .font(EnsoTheme.labelFont(9))
                        .tracking(1.6)
                        .foregroundStyle(inkLight)
                        .opacity(breathingOpacity)
                }
                .opacity(0.25)
                .padding(.bottom, 36)
                .onTapGesture { onSwipeUp() }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.height < -50 { onSwipeUp() }
                }
        )
        .onChange(of: store.progress) { _, newVal in
            withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.8)) {
                animatedProgress = newVal
            }
        }
        .onAppear {
            animatedProgress = store.progress
        }
    }

    // MARK: - Breathing animation for swipe cue

    @State private var breathingOpacity: Double = 0.4

    // MARK: - Log Water

    private func logWater(at location: CGPoint) {
        store.logGlass()

        // Haptic
        if store.hapticsEnabled {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }

        // Ripple
        let ripple = (id: UUID(), position: location)
        ripples.append(ripple)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            ripples.removeAll { $0.id == ripple.id }
        }

        // Toast
        withAnimation(.easeOut(duration: 0.3)) {
            toastText = "\(store.todayMl.formatted()) ml"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeIn(duration: 0.3)) { toastText = nil }
        }

        // Completion effect
        if store.isComplete && store.glasses == store.maxGlasses {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.5)) { showInkWash = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation(.easeInOut(duration: 0.5)) { showInkWash = false }
                }
            }
        }
    }
}
```

**Step 4: Commit**

```bash
git add -A && git commit -m "feat: add main screen with enso, ripples, seal, and interactions"
```

---

### Task 11: Stats Screen

**Files:**
- Create: `Enso/Views/StatsScreen/StatsView.swift`
- Create: `Enso/Views/StatsScreen/WeeklyChartView.swift`
- Create: `Enso/Views/StatsScreen/ConditionsGridView.swift`
- Create: `Enso/Views/StatsScreen/SmartBreakdownView.swift`

**Step 1: Create WeeklyChartView**

```swift
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
```

**Step 2: Create ConditionsGridView**

```swift
import SwiftUI

struct ConditionsGridView: View {
    let cells: [(value: String, label: String)]
    let columns: Int
    let isDark: Bool

    var body: some View {
        let inkColor = EnsoTheme.adaptive(EnsoTheme.ink, EnsoTheme.inkDark, isDark: isDark)
        let fadedColor = EnsoTheme.adaptive(EnsoTheme.inkFaded, EnsoTheme.inkFadedDark, isDark: isDark)
        let whisperColor = EnsoTheme.adaptive(EnsoTheme.inkWhisper, EnsoTheme.inkWhisperDark, isDark: isDark)

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
                .background(EnsoTheme.adaptive(EnsoTheme.paper, EnsoTheme.paperDark, isDark: isDark))
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
```

**Step 3: Create SmartBreakdownView**

```swift
import SwiftUI

struct SmartBreakdownView: View {
    let result: SmartGoalResult
    let isDark: Bool

    var body: some View {
        let inkColor = EnsoTheme.adaptive(EnsoTheme.ink, EnsoTheme.inkDark, isDark: isDark)
        let midColor = EnsoTheme.adaptive(EnsoTheme.inkMid, EnsoTheme.inkMidDark, isDark: isDark)
        let fadedColor = EnsoTheme.adaptive(EnsoTheme.inkFaded, EnsoTheme.inkFadedDark, isDark: isDark)
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
```

**Step 4: Create StatsView**

```swift
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
        hours > 0 ? String(format: "%.1fh", hours) : "—"
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
```

**Step 5: Commit**

```bash
git add -A && git commit -m "feat: add stats screen with weekly chart, conditions, smart breakdown"
```

---

### Task 12: Settings Screen

**Files:**
- Create: `Enso/Views/SettingsScreen/SettingsView.swift`

**Step 1: Create SettingsView**

```swift
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
                    settingRow(name: "Glass size", isDark: isDark) {
                        StepperControl(
                            value: $store.glassSize,
                            range: 50...1000,
                            step: 50,
                            format: { "\($0) ml" },
                            isDark: isDark
                        )
                    }
                    settingRow(name: "Daily goal", isDark: isDark) {
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
                    settingRow(name: "Apple Watch", isDark: isDark) {
                        Text(healthKitAuthorized ? "connected" : "not connected")
                            .font(EnsoTheme.labelFont(12))
                            .foregroundStyle(healthKitAuthorized ? syncGreen : fadedColor)
                            .tracking(0.5)
                    }
                    settingRow(name: "HealthKit", isDark: isDark) {
                        Text(healthKitAuthorized ? "authorized" : "not authorized")
                            .font(EnsoTheme.labelFont(12))
                            .foregroundStyle(healthKitAuthorized ? syncGreen : fadedColor)
                            .tracking(0.5)
                    }
                    settingRow(name: "Weather", isDark: isDark, showDivider: false) {
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
                    settingToggleRow(name: "Adapt to activity", isOn: $store.adaptToActivity, isDark: isDark)
                    settingToggleRow(name: "Adapt to weather", isOn: $store.adaptToWeather, isDark: isDark)
                    settingToggleRow(name: "Quiet during sleep", isOn: $store.quietDuringSleep, isDark: isDark, showDivider: false)
                }

                // Notifications
                settingGroup(title: "notifications") {
                    settingToggleRow(name: "Reminders", isOn: $store.notificationsEnabled, isDark: isDark)
                    settingToggleRow(name: "Haptics", isOn: $store.hapticsEnabled, isDark: isDark, showDivider: false)
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

    // MARK: - Setting Group

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

    // MARK: - Setting Row

    @ViewBuilder
    private func settingRow(name: String, isDark: Bool, showDivider: Bool = true, @ViewBuilder trailing: () -> some View) -> some View {
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

    // MARK: - Toggle Row

    @ViewBuilder
    private func settingToggleRow(name: String, isOn: Binding<Bool>, isDark: Bool, showDivider: Bool = true) -> some View {
        settingRow(name: name, isDark: isDark, showDivider: showDivider) {
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
```

**Step 2: Commit**

```bash
git add -A && git commit -m "feat: add settings screen with steppers, toggles, data sources"
```

---

### Task 13: Wire Up EnsoApp & Build

**Files:**
- Modify: `Enso/EnsoApp.swift`

**Step 1: Update app entry point to ensure state is shared**

```swift
import SwiftUI

@main
struct EnsoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
```

**Step 2: Update project.yml with font resources and frameworks**

Add to the Enso target in `project.yml`:

```yaml
    settings:
      base:
        INFOPLIST_FILE: Enso/Info.plist
        PRODUCT_BUNDLE_IDENTIFIER: com.personal.enso
    entitlements:
      path: Enso/Enso.entitlements
    dependencies:
      - sdk: HealthKit.framework
      - sdk: WeatherKit.framework
      - sdk: CoreLocation.framework
```

**Step 3: Build and fix any compilation errors**

Run: `xcodegen generate && xcodebuild -project Enso.xcodeproj -scheme Enso -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 2>&1 | tail -20`

Fix any issues that arise.

**Step 4: Commit**

```bash
git add -A && git commit -m "feat: wire up app entry point and build"
```

---

### Task 14: Test on Simulator

**Step 1: Run on simulator**

Run: `xcodebuild -project Enso.xcodeproj -scheme Enso -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build`
Then: `open -a Simulator && xcrun simctl boot "iPhone 15 Pro" && xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/Enso.app && xcrun simctl launch booted com.personal.enso`

**Step 2: Verify each screen**

Compare against `index.html` mockup:
- [ ] Main screen: enso renders, tap logs water, ripple animates, toast appears
- [ ] Progress label appears after first tap
- [ ] Completion seal + ink wash at goal
- [ ] Swipe up transitions to stats
- [ ] Stats: today intake, weekly chart, Apple Watch grid, weather grid, smart breakdown
- [ ] Settings: opens from gear, steppers work, toggles work, reset works
- [ ] Dark mode toggle works
- [ ] Typography matches (Shippori Mincho + Cormorant Garamond)
- [ ] Colors match mockup exactly

**Step 3: Commit any fixes**

```bash
git add -A && git commit -m "fix: polish UI to match mockup exactly"
```

---

Plan complete and saved to `docs/plans/2026-03-11-enso-implementation.md`. Two execution options:

**1. Subagent-Driven (this session)** — I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** — Open new session with executing-plans, batch execution with checkpoints

Which approach?
