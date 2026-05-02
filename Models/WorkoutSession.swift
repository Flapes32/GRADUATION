//
//  WorkoutSession.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import Foundation

/// Тип этапа тренировки
enum WorkoutPhase: String, Codable {
    case warmup = "Разминка"
    case active = "Рабочий раунд"
    case sprint = "Спринт"
    case rest = "Отдых"
}

/// Сессия тренировки
struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    var endDate: Date?
    var phases: [WorkoutPhase]
    var heartRateData: [HeartRateData]
    var lactateData: [LactateData]
    var peakLoads: [PeakLoad]
    var peakLactate: Double?
    var recoveryTime: TimeInterval? // Время восстановления лактата до нормы
    var caloriesBurned: Double? // Сожженные калории
    
    var duration: TimeInterval? {
        guard let endDate = endDate else { return nil }
        return endDate.timeIntervalSince(startDate)
    }
    
    var isActive: Bool {
        return endDate == nil
    }
    
    init(id: UUID = UUID(), startDate: Date = Date(), endDate: Date? = nil) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.phases = []
        self.heartRateData = []
        self.lactateData = []
        self.peakLoads = []
    }
}

/// Скорость падения ЧСС во время отдыха
struct HeartRateRecovery: Codable {
    let initialHeartRate: Double
    let heartRateAfter30Seconds: Double
    let dropRate: Double // Ударов в минуту за 30 секунд
    let timestamp: Date
    
    init(initialHeartRate: Double, heartRateAfter30Seconds: Double, timestamp: Date = Date()) {
        self.initialHeartRate = initialHeartRate
        self.heartRateAfter30Seconds = heartRateAfter30Seconds
        self.dropRate = initialHeartRate - heartRateAfter30Seconds
        self.timestamp = timestamp
    }
}

