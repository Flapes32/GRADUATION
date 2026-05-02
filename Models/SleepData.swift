//
//  SleepData.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import Foundation

/// Данные о сне
struct SleepData: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let averageHeartRate: Double?
    let sleepPhases: [SleepPhase]
    
    var durationInHours: Double {
        return duration / 3600.0
    }
    
    init(id: UUID = UUID(), startDate: Date, endDate: Date, averageHeartRate: Double? = nil, sleepPhases: [SleepPhase] = []) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.duration = endDate.timeIntervalSince(startDate)
        self.averageHeartRate = averageHeartRate
        self.sleepPhases = sleepPhases
    }
}

/// Фаза сна
struct SleepPhase: Identifiable, Codable {
    let id: UUID
    let type: SleepPhaseType
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    
    init(id: UUID = UUID(), type: SleepPhaseType, startDate: Date, endDate: Date) {
        self.id = id
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
        self.duration = endDate.timeIntervalSince(startDate)
    }
}

/// Тип фазы сна
enum SleepPhaseType: String, Codable {
    case awake = "Бодрствование"
    case rem = "REM"
    case light = "Легкий сон"
    case deep = "Глубокий сон"
    
    var color: String {
        switch self {
        case .awake: return "red"
        case .rem: return "purple"
        case .light: return "blue"
        case .deep: return "indigo"
        }
    }
}

/// Рекомендации по сну
struct SleepRecommendation: Codable {
    let optimalBedtime: Date?
    let recommendedDuration: TimeInterval
    let tips: [String]
    
    init(optimalBedtime: Date? = nil, recommendedDuration: TimeInterval = 8 * 3600, tips: [String] = []) {
        self.optimalBedtime = optimalBedtime
        self.recommendedDuration = recommendedDuration
        self.tips = tips
    }
}

