//
//  HeartRateData.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import Foundation
import HealthKit

/// Модель данных сердечного ритма
struct HeartRateData: Identifiable, Codable {
    let id: UUID
    let value: Double // ЧСС в ударах в минуту
    let timestamp: Date
    let workoutSessionId: UUID?
    
    init(id: UUID = UUID(), value: Double, timestamp: Date = Date(), workoutSessionId: UUID? = nil) {
        self.id = id
        self.value = value
        self.timestamp = timestamp
        self.workoutSessionId = workoutSessionId
    }
}

/// Целевая зона ЧСС
struct HeartRateZone: Codable {
    let min: Double
    let max: Double
    let name: String
    let color: ZoneColor
    
    enum ZoneColor: String, Codable {
        case warmup = "Разминка"
        case aerobic = "Аэробная"
        case anaerobic = "Анаэробная"
        case maximum = "Максимальная"
    }
    
    func contains(_ heartRate: Double) -> Bool {
        return heartRate >= min && heartRate <= max
    }
}

/// Статус восстановления
enum RecoveryStatus: String, Codable {
    case ready = "Готов"
    case partial = "Частичное восстановление"
    case risk = "Высокий риск"
    
    var color: String {
        switch self {
        case .ready: return "green"
        case .partial: return "yellow"
        case .risk: return "red"
        }
    }
}

