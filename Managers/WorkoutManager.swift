import Foundation
import CoreMotion
import Combine

// MARK: - Lactate Predictor

class LactatePredictor: ObservableObject {
    @Published var currentLactate: Double = 1.0
    @Published var recoveryStatus: LactateData.RecoveryStatus = .ready
    @Published var peakLactate: Double = 0

    private var maxHeartRate: Int = 190
    private var hrHistory: [Double] = []
    private let motionManager = CMMotionManager()

    private var accelerationMagnitude: Double = 0

    func configure(maxHR: Int) {
        self.maxHeartRate = maxHR
        startMotionTracking()
    }

    func update(heartRate: Double, phase: WorkoutPhase) {
        hrHistory.append(heartRate)
        if hrHistory.count > 10 { hrHistory.removeFirst() }

        let hrPercent = heartRate / Double(maxHeartRate)
        let estimated = estimateLactate(hrPercent: hrPercent, phase: phase)

        DispatchQueue.main.async {
            self.currentLactate = estimated
            self.recoveryStatus = LactateData.calculateRecovery(level: estimated)
            if estimated > self.peakLactate { self.peakLactate = estimated }
        }
    }

    private func estimateLactate(hrPercent: Double, phase: WorkoutPhase) -> Double {
        // Physics-based model:
        // < 60% HR → ~1-2 mmol/L (rest)
        // 60-80%  → 2-4 mmol/L (aerobic)
        // 80-90%  → 4-8 mmol/L (threshold)
        // > 90%   → 8-14 mmol/L (anaerobic)

        let baseLactate: Double
        switch hrPercent {
        case ..<0.60: baseLactate = 1.5
        case 0.60..<0.75: baseLactate = 1.5 + (hrPercent - 0.60) / 0.15 * 2.5
        case 0.75..<0.85: baseLactate = 4.0 + (hrPercent - 0.75) / 0.10 * 3.0
        case 0.85..<0.92: baseLactate = 7.0 + (hrPercent - 0.85) / 0.07 * 3.0
        default:          baseLactate = 10.0 + (hrPercent - 0.92) / 0.08 * 4.0
        }

        // Motion multiplier (more movement = more lactate)
        let motionMultiplier = 1.0 + min(accelerationMagnitude * 0.3, 0.5)

        // Recovery in rest phase: lactate decreases
        if phase == .rest && hrHistory.count >= 3 {
            let recoveryRate = calculateRecoveryRate()
            return max(1.0, currentLactate - recoveryRate * 0.5)
        }

        return min(baseLactate * motionMultiplier, 20.0)
    }

    private func calculateRecoveryRate() -> Double {
        guard hrHistory.count >= 2 else { return 0 }
        let drop = hrHistory[hrHistory.count - 2] - hrHistory[hrHistory.count - 1]
        return max(0, drop / 10.0) // ~0.3-0.5 mmol/L per heartbeat drop
    }

    private func startMotionTracking() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data = data else { return }
            let x = data.acceleration.x
            let y = data.acceleration.y
            let z = data.acceleration.z
            self?.accelerationMagnitude = sqrt(x*x + y*y + z*z)
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }

    func reset() {
        currentLactate = 1.0
        peakLactate = 0
        hrHistory.removeAll()
        recoveryStatus = .ready
    }
}

// MARK: - Workout Manager

class WorkoutManager: ObservableObject {
    static let shared = WorkoutManager()

    @Published var isWorkoutActive: Bool = false
    @Published var currentPhase: WorkoutPhase = .warmup
    @Published var currentRound: Int = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentHeartRate: Double = 0
    @Published var peakHeartRates: Int = 0  // times HR > 95% of max
    @Published var currentSession: WorkoutSession?

    var maxHeartRate: Int { userProfile.maxHeartRate }

    private let healthKit = HealthKitManager.shared
    private let watchSession = WatchSessionManager.shared
    let lactatePredictor = LactatePredictor()
    private let repository = WorkoutRepository()

    private var timer: Timer?
    private var roundStartTime: Date?
    private var sessionHeartRates: [Double] = []
    private var userProfile = UserProfile()

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Forward HR from HealthKit to lactate predictor
        healthKit.$currentHeartRate
            .receive(on: RunLoop.main)
            .sink { [weak self] hr in
                guard let self = self, hr > 0, self.isWorkoutActive else { return }
                self.currentHeartRate = hr
                self.sessionHeartRates.append(hr)
                self.lactatePredictor.update(heartRate: hr, phase: self.currentPhase)
                if hr / Double(self.userProfile.maxHeartRate) > 0.95 {
                    self.peakHeartRates += 1
                }
            }
            .store(in: &cancellables)
    }

    func configure(profile: UserProfile) {
        self.userProfile = profile
        lactatePredictor.configure(maxHR: profile.maxHeartRate)
        watchSession.updateApplicationContext(userProfile: profile)
    }

    // MARK: - Start / Stop

    func startWorkout(phase: WorkoutPhase = .warmup) async {
        let config = HKWorkoutConfiguration()
        config.activityType = .boxing
        config.locationType = .indoor

        do {
            try await healthKit.startWorkoutSession(configuration: config)
        } catch {
            print("Workout start error: \(error)")
        }

        await MainActor.run {
            self.isWorkoutActive = true
            self.currentPhase = phase
            self.currentRound = 1
            self.elapsedTime = 0
            self.peakHeartRates = 0
            self.sessionHeartRates = []
            self.currentSession = WorkoutSession(phase: phase)
            self.roundStartTime = Date()
            self.lactatePredictor.reset()
            self.startTimer()
        }

        watchSession.sendStartWorkout(phase: phase, userProfile: userProfile)
    }

    func stopWorkout() async {
        stopTimer()
        watchSession.sendStopWorkout()
        lactatePredictor.stop()

        if var session = await healthKit.stopWorkoutSession() {
            session.averageHRV = await healthKit.fetchHRV()
            session.peakLactate = lactatePredictor.peakLactate

            // Save heart rate records
            let records = healthKit.heartRateHistory.filter {
                $0.timestamp >= (session.startDate)
            }.map {
                HeartRateRecord(value: $0.value, timestamp: $0.timestamp,
                                workoutSessionId: session.id)
            }
            repository.saveHeartRateRecords(records)
            repository.saveWorkout(session)

            await MainActor.run { self.currentSession = session }

            // Update achievements
            updateAchievements(session: session)
        }

        await MainActor.run {
            self.isWorkoutActive = false
            self.currentRound = 0
            self.elapsedTime = 0
        }
    }

    // MARK: - Phase / Round Management

    func changePhase(_ phase: WorkoutPhase) {
        finishCurrentRound()
        currentPhase = phase

        if phase == .round {
            currentRound += 1
            roundStartTime = Date()
        }

        watchSession.sendPhaseUpdate(phase)
    }

    private func finishCurrentRound() {
        guard currentPhase == .round,
              let start = roundStartTime else { return }
        let duration = Date().timeIntervalSince(start)
        let recentHR = sessionHeartRates.suffix(Int(duration / 2))

        var round = RoundData(number: currentRound)
        round.duration = duration
        round.averageHeartRate = recentHR.isEmpty ? 0 : recentHR.reduce(0,+) / Double(recentHR.count)
        round.maxHeartRate = recentHR.max() ?? 0
        round.peakLactate = lactatePredictor.peakLactate

        currentSession?.rounds.append(round)
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedTime += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Achievements

    private func updateAchievements(session: WorkoutSession) {
        var achievements = repository.fetchAchievements()

        // Workout count
        let totalWorkouts = Double(repository.totalWorkoutsCount())
        if let idx = achievements.firstIndex(where: { $0.title == "Первые шаги" }) {
            achievements[idx].progress = totalWorkouts
            if totalWorkouts >= achievements[idx].total { achievements[idx].isCompleted = true }
            repository.updateAchievement(achievements[idx])
        }

        // Total calories
        let totalCal = repository.totalCaloriesBurned()
        if let idx = achievements.firstIndex(where: { $0.title == "Жиросжигатель" }) {
            achievements[idx].progress = totalCal
            if totalCal >= achievements[idx].total { achievements[idx].isCompleted = true }
            repository.updateAchievement(achievements[idx])
        }

        // Peak HR achievement
        let hrPercent = session.maxHeartRate / Double(userProfile.maxHeartRate)
        if hrPercent >= 0.95,
           let idx = achievements.firstIndex(where: { $0.title == "Пульс чемпиона" }) {
            achievements[idx].progress = 1
            achievements[idx].isCompleted = true
            achievements[idx].completedDate = Date()
            repository.updateAchievement(achievements[idx])
        }
    }
}
