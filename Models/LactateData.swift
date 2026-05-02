//
//  LactateData.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import Foundation

/// Прогнозируемый уровень лактата
struct LactateData: Identifiable, Codable {
    let id: UUID
    let predictedValue: Double // Прогнозируемое значение в условных единицах
    let timestamp: Date
    let workoutSessionId: UUID?
    
    init(id: UUID = UUID(), predictedValue: Double, timestamp: Date = Date(), workoutSessionId: UUID? = nil) {
        self.id = id
        self.predictedValue = predictedValue
        self.timestamp = timestamp
        self.workoutSessionId = workoutSessionId
    }
}

/// Уровень закисления
enum LactateLevel: String, Codable {
    case normal = "Норма"
    case moderate = "Умеренное"
    case high = "Высокое"
    case peak = "Пик"
    
    var threshold: Double {
        switch self {
        case .normal: return 0.3
        case .moderate: return 0.6
        case .high: return 0.8
        case .peak: return 1.0
        }
    }
    
    static func fromValue(_ value: Double) -> LactateLevel {
        if value <= 0.3 { return .normal }
        if value <= 0.6 { return .moderate }
        if value <= 0.8 { return .high }
        return .peak
    }
}

/// Данные о пиковой нагрузке
struct PeakLoad: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let heartRate: Double
    let percentageOfMax: Double // Процент от максимального ЧСС
    let workoutSessionId: UUID?
    
    init(id: UUID = UUID(), timestamp: Date = Date(), heartRate: Double, percentageOfMax: Double, workoutSessionId: UUID? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.heartRate = heartRate
        self.percentageOfMax = percentageOfMax
        self.workoutSessionId = workoutSessionId
    }
}

