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
            updateAuthorizationStatus()
        } catch {
            print("HealthKit auth failed: \(error)")
        }
    }

    /// Check actual per-type authorization status.
    /// HealthKit returns .notDetermined before first query and .sharingDenied for read types
    /// that haven't been granted. The only reliable way to know if read access works is to
    /// attempt a query — but we can at least check if the user hasn't explicitly denied sharing.
    /// For read-only access, HealthKit intentionally hides denial (privacy), so we check
    /// if we can successfully fetch *any* data as a proxy.
    func updateAuthorizationStatus() {
        // For read permissions, HealthKit always returns .notDetermined (privacy).
        // The best heuristic: if health data is available and we've requested auth, treat as authorized.
        // We'll refine this in fetchTodayData by checking if we actually got data back.
        // HealthKit intentionally hides read authorization status for privacy.
        // If health data is available and requestAuthorization didn't throw, the dialog was shown.
        isAuthorized = HKHealthStore.isHealthDataAvailable()
    }

    /// After fetching, refine authorization status based on whether we got real data.
    func updateAuthorizationFromData(_ data: HealthData) {
        let hasAnyData = data.steps > 0
            || data.activeCalories > 0
            || data.avgHeartRate > 0
            || data.sleepHours > 0
            || data.workout != nil
        if hasAnyData {
            isAuthorized = true
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

    private func querySum(_ type: HKQuantityTypeIdentifier, from: Date, to: Date) async -> Double {
        let quantityType = HKQuantityType(type)
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate.quantitySample(type: quantityType, predicate: predicate),
            options: .cumulativeSum
        )
        do {
            let result = try await descriptor.result(for: store)
            let unit: HKUnit = type == .activeEnergyBurned ? .kilocalorie() : .count()
            return result?.sumQuantity()?.doubleValue(for: unit) ?? 0
        } catch {
            print("HealthKit querySum(\(type)) error: \(error)")
            return 0
        }
    }

    private func queryAverage(_ type: HKQuantityTypeIdentifier, from: Date, to: Date) async -> Double {
        let quantityType = HKQuantityType(type)
        let predicate = HKQuery.predicateForSamples(withStart: from, end: to)
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate.quantitySample(type: quantityType, predicate: predicate),
            options: .discreteAverage
        )
        do {
            let result = try await descriptor.result(for: store)
            let unit: HKUnit = type == .heartRate
                ? HKUnit.count().unitDivided(by: .minute())
                : .count()
            return result?.averageQuantity()?.doubleValue(for: unit) ?? 0
        } catch {
            print("HealthKit queryAverage(\(type)) error: \(error)")
            return 0
        }
    }

    private func querySleep(for date: Date) async -> (hours: Double, wakeTime: Date?, bedTime: Date?) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Window: yesterday 6 PM → today noon — captures only the primary overnight sleep
        let sleepWindowStart = calendar.date(byAdding: .hour, value: -6, to: startOfDay)! // yesterday 18:00
        let sleepWindowEnd = calendar.date(byAdding: .hour, value: 12, to: startOfDay)!   // today 12:00
        let end = min(sleepWindowEnd, date)

        let predicate = HKQuery.predicateForSamples(withStart: sleepWindowStart, end: end)
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

            // Also check for inBed samples to calculate "Time in Bed" (matches Health app)
            let inBedSamples = samples.filter { sample in
                let val = HKCategoryValueSleepAnalysis(rawValue: sample.value)
                return val == .inBed
            }

            // If we have inBed samples, use them for the time span (matches Health "Time in Bed")
            // Otherwise fall back to asleep sample span
            let bedTime: Date?
            let wakeTime: Date?

            if !inBedSamples.isEmpty {
                let sortedInBed = inBedSamples.sorted { $0.startDate < $1.startDate }
                bedTime = sortedInBed.first?.startDate
                wakeTime = sortedInBed.last?.endDate
            } else {
                let sortedAsleep = asleepSamples.sorted { $0.startDate < $1.startDate }
                bedTime = sortedAsleep.first?.startDate
                wakeTime = sortedAsleep.last?.endDate
            }

            // "Time in Bed" = span from bed to wake
            let totalSeconds: Double
            if let bed = bedTime, let wake = wakeTime {
                totalSeconds = wake.timeIntervalSince(bed)
            } else {
                totalSeconds = 0
            }

            return (totalSeconds / 3600, wakeTime, bedTime)
        } catch {
            print("HealthKit querySleep error: \(error)")
            return (0, nil, nil)
        }
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
        } catch {
            print("HealthKit queryLatestWorkout error: \(error)")
            return nil
        }
    }
}

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
