import HealthKit
import Combine
import Foundation

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    @Published var currentHeartRate: Double = 0
    @Published var currentHRV: Double = 0
    @Published var currentCalories: Double = 0
    @Published var isAuthorized: Bool = false
    @Published var heartRateHistory: [HeartRateRecord] = []

    private var heartRateQuery: HKAnchoredObjectQuery?
    private var observerQuery: HKObserverQuery?
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var heartRateSamples: [Double] = []

    // MARK: - Types

    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.workoutType()
    ]

    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.workoutType()
    ]

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            await MainActor.run { self.isAuthorized = true }
            return true
        } catch {
            print("HealthKit auth error: \(error)")
            return false
        }
    }

    // MARK: - Workout Session

    func startWorkoutSession(configuration: HKWorkoutConfiguration) async throws {
        let session = try HKWorkoutSession(healthStore: store, configuration: configuration)
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: store,
                                                      workoutConfiguration: configuration)
        self.workoutSession = session
        self.workoutBuilder = builder
        session.startActivity(with: Date())
        try await builder.beginCollection(at: Date())
        startHeartRateStreaming()
    }

    func stopWorkoutSession() async -> WorkoutSession? {
        guard let session = workoutSession, let builder = workoutBuilder else { return nil }

        session.end()
        do {
            try await builder.endCollection(at: Date())
            let hkWorkout = try await builder.finishWorkout()
            stopHeartRateStreaming()

            var ws = WorkoutSession()
            ws.endDate         = hkWorkout.endDate
            ws.duration        = hkWorkout.duration
            ws.totalCalories   = hkWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
            ws.averageHeartRate = heartRateSamples.isEmpty ? 0
                                  : heartRateSamples.reduce(0,+) / Double(heartRateSamples.count)
            ws.maxHeartRate    = heartRateSamples.max() ?? 0
            ws.minHeartRate    = heartRateSamples.min() ?? 0
            heartRateSamples.removeAll()
            return ws
        } catch {
            print("Stop workout error: \(error)")
            return nil
        }
    }

    // MARK: - Heart Rate Streaming

    func startHeartRateStreaming() {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil)
        var anchor: HKQueryAnchor?

        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: predicate,
            anchor: anchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, newAnchor, _ in
            anchor = newAnchor
            self?.processHeartRateSamples(samples)
        }

        query.updateHandler = { [weak self] _, samples, _, newAnchor, _ in
            anchor = newAnchor
            self?.processHeartRateSamples(samples)
        }

        heartRateQuery = query
        store.execute(query)
    }

    func stopHeartRateStreaming() {
        if let q = heartRateQuery { store.stop(q) }
        heartRateQuery = nil
    }

    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        let unit = HKUnit.count().unitDivided(by: .minute())
        let records: [HeartRateRecord] = samples.map {
            let bpm = $0.quantity.doubleValue(for: unit)
            heartRateSamples.append(bpm)
            return HeartRateRecord(value: bpm, timestamp: $0.startDate)
        }

        DispatchQueue.main.async {
            if let latest = records.last { self.currentHeartRate = latest.value }
            self.heartRateHistory.append(contentsOf: records)
        }
    }

    // MARK: - Historical Queries

    func fetchHeartRateHistory(days: Int = 1) async -> [HeartRateRecord] {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return [] }
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: hrType, predicate: predicate,
                                       limit: 500, sortDescriptors: [sort]) { _, samples, _ in
                let unit = HKUnit.count().unitDivided(by: .minute())
                let records = (samples as? [HKQuantitySample] ?? []).map {
                    HeartRateRecord(value: $0.quantity.doubleValue(for: unit),
                                    timestamp: $0.startDate)
                }
                continuation.resume(returning: records)
            }
            store.execute(query)
        }
    }

    func fetchHRV() async -> Double {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return 0 }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: hrvType, predicate: nil,
                                       limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let val = (samples as? [HKQuantitySample])?.first?
                    .quantity.doubleValue(for: .secondUnit(with: .milli)) ?? 0
                continuation.resume(returning: val)
            }
            store.execute(query)
        }
    }

    func fetchSleepData(days: Int = 7) async -> [SleepData] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate,
                                       limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }

                // Group by night
                let grouped = Dictionary(grouping: samples) { sample -> String in
                    let cal = Calendar.current
                    let day = cal.date(byAdding: .hour, value: -12, to: sample.startDate) ?? sample.startDate
                    return cal.startOfDay(for: day).description
                }

                let sleepDataList: [SleepData] = grouped.values.compactMap { nightSamples in
                    guard let start = nightSamples.map({ $0.startDate }).min(),
                          let end = nightSamples.map({ $0.endDate }).max() else { return nil }

                    var sleep = SleepData(startDate: start, endDate: end)
                    let total = end.timeIntervalSince(start)
                    guard total > 0 else { return nil }

                    let deepTime = nightSamples
                        .filter { $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue }
                        .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                    let remTime = nightSamples
                        .filter { $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }
                        .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                    let awakeTime = nightSamples
                        .filter { $0.value == HKCategoryValueSleepAnalysis.awake.rawValue }
                        .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

                    sleep.deepSleepPercent = deepTime / total * 100
                    sleep.remSleepPercent  = remTime  / total * 100
                    sleep.awakePercent     = awakeTime / total * 100

                    // Quality: 40% duration + 30% deep + 30% awake penalty
                    let durationScore = min(sleep.durationInHours / 8.0, 1.0) * 40
                    let deepScore     = min(sleep.deepSleepPercent / 25.0, 1.0) * 30
                    let awakePenalty  = max(0, 1.0 - sleep.awakePercent / 20.0) * 30
                    sleep.qualityScore = durationScore + deepScore + awakePenalty

                    return sleep
                }.sorted { $0.startDate > $1.startDate }

                continuation.resume(returning: sleepDataList)
            }
            store.execute(query)
        }
    }

    func fetchRestingHeartRate() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else { return 0 }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil,
                                       limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let val = (samples as? [HKQuantitySample])?.first?
                    .quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
                continuation.resume(returning: val)
            }
            store.execute(query)
        }
    }
}
