import Foundation
import HealthKit

// MARK: - Workout Session

struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    var startDate: Date
    var endDate: Date?
    var duration: TimeInterval
    var averageHeartRate: Double
    var maxHeartRate: Double
    var minHeartRate: Double
    var totalCalories: Double
    var averageHRV: Double
    var peakLactate: Double
    var rounds: [RoundData]
    var phase: WorkoutPhase

    init(id: UUID = UUID(), startDate: Date = Date(), phase: WorkoutPhase = .warmup) {
        self.id = id
        self.startDate = startDate
        self.duration = 0
        self.averageHeartRate = 0
        self.maxHeartRate = 0
        self.minHeartRate = 220
        self.totalCalories = 0
        self.averageHRV = 0
        self.peakLactate = 0
        self.rounds = []
        self.phase = phase
    }
}

enum WorkoutPhase: String, Codable, CaseIterable {
    case warmup   = "Разминка"
    case round    = "Раунд"
    case rest     = "Отдых"
    case sprint   = "Спринт"
    case cooldown = "Заминка"

    var targetHRPercent: ClosedRange<Double> {
        switch self {
        case .warmup:   return 0.60...0.70
        case .round:    return 0.85...0.95
        case .rest:     return 0.50...0.65
        case .sprint:   return 0.95...1.00
        case .cooldown: return 0.50...0.60
        }
    }

    var color: String {
        switch self {
        case .warmup:   return "orange"
        case .round:    return "red"
        case .rest:     return "green"
        case .sprint:   return "purple"
        case .cooldown: return "blue"
        }
    }
}

// MARK: - Round Data

struct RoundData: Identifiable, Codable {
    let id: UUID
    var number: Int
    var duration: TimeInterval
    var averageHeartRate: Double
    var maxHeartRate: Double
    var peakLactate: Double
    var calories: Double
    var startDate: Date
    var endDate: Date?

    init(number: Int) {
        self.id = UUID()
        self.number = number
        self.duration = 0
        self.averageHeartRate = 0
        self.maxHeartRate = 0
        self.peakLactate = 0
        self.calories = 0
        self.startDate = Date()
    }
}

// MARK: - Heart Rate Record

struct HeartRateRecord: Identifiable, Codable {
    let id: UUID
    var value: Double        // bpm
    var timestamp: Date
    var workoutSessionId: UUID?

    init(value: Double, timestamp: Date = Date(), workoutSessionId: UUID? = nil) {
        self.id = UUID()
        self.value = value
        self.timestamp = timestamp
        self.workoutSessionId = workoutSessionId
    }
}

// MARK: - Sleep Data

struct SleepData: Identifiable, Codable {
    let id: UUID
    var startDate: Date
    var endDate: Date
    var durationInHours: Double
    var deepSleepPercent: Double
    var remSleepPercent: Double
    var awakePercent: Double
    var qualityScore: Double      // 0-100

    init(startDate: Date, endDate: Date) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.durationInHours = endDate.timeIntervalSince(startDate) / 3600
        self.deepSleepPercent = 0
        self.remSleepPercent = 0
        self.awakePercent = 0
        self.qualityScore = 0
    }

    var qualityLabel: String {
        switch qualityScore {
        case 80...100: return "Отлично"
        case 60..<80:  return "Хорошо"
        case 40..<60:  return "Среднее"
        default:       return "Плохое"
    }
    }
}

// MARK: - Lactate Data

struct LactateData: Identifiable, Codable {
    let id: UUID
    var estimatedLevel: Double   // mmol/L
    var timestamp: Date
    var heartRatePercent: Double
    var recoveryStatus: RecoveryStatus

    enum RecoveryStatus: String, Codable {
        case ready    = "Готов"
        case moderate = "Умеренно"
        case tired    = "Устал"
        case critical = "Критично"

        var color: String {
            switch self {
            case .ready:    return "green"
            case .moderate: return "yellow"
            case .tired:    return "orange"
            case .critical: return "red"
            }
        }
    }

    init(estimatedLevel: Double, heartRatePercent: Double, timestamp: Date = Date()) {
        self.id = UUID()
        self.estimatedLevel = estimatedLevel
        self.heartRatePercent = heartRatePercent
        self.timestamp = timestamp
        self.recoveryStatus = LactateData.calculateRecovery(level: estimatedLevel)
    }

    static func calculateRecovery(level: Double) -> RecoveryStatus {
        switch level {
        case ..<4:    return .ready
        case 4..<8:   return .moderate
        case 8..<12:  return .tired
        default:      return .critical
        }
    }
}

// MARK: - Achievement

struct Achievement: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var icon: String
    var progress: Double
    var total: Double
    var isCompleted: Bool
    var completedDate: Date?

    var progressPercent: Double { min(progress / total, 1.0) }

    init(title: String, description: String, icon: String, total: Double) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.icon = icon
        self.progress = 0
        self.total = total
        self.isCompleted = false
    }
}

// MARK: - User Profile

struct UserProfile: Codable {
    var age: Int
    var weight: Double   // kg
    var maxHeartRate: Int { 220 - age }
    var name: String

    init(name: String = "Боксёр", age: Int = 25, weight: Double = 75) {
        self.name = name
        self.age = age
        self.weight = weight
    }
}

// MARK: - Watch Message Keys

enum WatchMessageKey {
    static let heartRate      = "heartRate"
    static let lactate        = "lactate"
    static let phase          = "phase"
    static let calories       = "calories"
    static let hrv            = "hrv"
    static let startWorkout   = "startWorkout"
    static let stopWorkout    = "stopWorkout"
    static let recoveryStatus = "recoveryStatus"
}
