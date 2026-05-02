import HealthKit
import Foundation
import Combine

class WatchHealthKitManager: ObservableObject {
    static let shared = WatchHealthKitManager()

    private let store = HKHealthStore()
    @Published var currentHeartRate: Double = 0
    @Published var totalCalories: Double = 0
    @Published var hrv: Double = 0

    private var workoutSession: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var heartRateSamples: [Double] = []

    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
    ]
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.workoutType()
    ]

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try? await store.requestAuthorization(toShare: writeTypes, read: readTypes)
    }

    // MARK: - Workout

    func startWorkout() async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .boxing
        config.locationType = .indoor

        let session = try HKWorkoutSession(healthStore: store, configuration: config)
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)

        self.workoutSession = session
        self.builder = builder

        session.delegate = self
        builder.delegate = self

        session.startActivity(with: Date())
        try await builder.beginCollection(at: Date())
    }

    func stopWorkout() async {
        workoutSession?.end()
        do {
            try await builder?.endCollection(at: Date())
            _ = try await builder?.finishWorkout()
        } catch {
            print("Watch stop workout error: \(error)")
        }
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchHealthKitManager: HKWorkoutSessionDelegate {
    func workoutSession(_ session: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {}
    func workoutSession(_ session: HKWorkoutSession, didFailWithError error: Error) {}
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WatchHealthKitManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }

            switch quantityType {
            case HKQuantityType(.heartRate):
                let unit = HKUnit.count().unitDivided(by: .minute())
                let stats = workoutBuilder.statistics(for: quantityType)
                let hr = stats?.mostRecentQuantity()?.doubleValue(for: unit) ?? 0
                DispatchQueue.main.async {
                    self.currentHeartRate = hr
                    self.heartRateSamples.append(hr)
                }
                // Forward to iPhone
                WatchConnectivityManager.shared.sendHeartRateUpdate(
                    hr,
                    lactate: estimateLactate(hrPercent: hr / Double(WatchConnectivityManager.shared.maxHeartRate)),
                    calories: self.totalCalories
                )

            case HKQuantityType(.activeEnergyBurned):
                let cal = workoutBuilder.statistics(for: quantityType)?
                    .sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                DispatchQueue.main.async { self.totalCalories = cal }

            default: break
            }
        }
    }

    private func estimateLactate(hrPercent: Double) -> Double {
        switch hrPercent {
        case ..<0.60: return 1.5
        case 0.60..<0.75: return 1.5 + (hrPercent - 0.60) / 0.15 * 2.5
        case 0.75..<0.85: return 4.0 + (hrPercent - 0.75) / 0.10 * 3.0
        case 0.85..<0.92: return 7.0 + (hrPercent - 0.85) / 0.07 * 3.0
        default: return 10.0 + min((hrPercent - 0.92) / 0.08 * 4.0, 4.0)
        }
    }
}
