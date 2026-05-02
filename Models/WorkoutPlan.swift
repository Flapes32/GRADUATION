//
//  WorkoutPlan.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import Foundation

/// Тип плана тренировки
enum PlanType: String, Codable, CaseIterable {
    case beginner = "Начинающий"
    case intermediate = "Средний"
    case advanced = "Продвинутый"
    case endurance = "Выносливость"
    case strength = "Сила"
    case speed = "Скорость"
    case recovery = "Восстановление"
    case custom = "Пользовательский"
}

/// Статус плана
enum PlanStatus: String, Codable {
    case active = "Активен"
    case completed = "Завершен"
    case paused = "Приостановлен"
    case notStarted = "Не начат"
}

/// План тренировки
struct WorkoutPlan: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var type: PlanType
    var duration: Int // Дней
    var workoutsPerWeek: Int
    var status: PlanStatus
    var startDate: Date?
    var endDate: Date?
    var currentWeek: Int
    var totalWeeks: Int
    var workouts: [PlanWorkout]
    var progress: Double // 0.0 - 1.0
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        type: PlanType,
        duration: Int,
        workoutsPerWeek: Int,
        status: PlanStatus = .notStarted,
        startDate: Date? = nil,
        endDate: Date? = nil,
        currentWeek: Int = 1,
        totalWeeks: Int,
        workouts: [PlanWorkout] = [],
        progress: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.duration = duration
        self.workoutsPerWeek = workoutsPerWeek
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.currentWeek = currentWeek
        self.totalWeeks = totalWeeks
        self.workouts = workouts
        self.progress = progress
    }
}

/// Тренировка в плане
struct PlanWorkout: Identifiable, Codable {
    let id: UUID
    var week: Int
    var day: Int // День недели (1-7)
    var name: String
    var description: String
    var duration: TimeInterval // Минуты
    var targetHeartRate: HeartRateZone?
    var phases: [WorkoutPhase]
    var isCompleted: Bool
    var completedDate: Date?
    
    init(
        id: UUID = UUID(),
        week: Int,
        day: Int,
        name: String,
        description: String,
        duration: TimeInterval,
        targetHeartRate: HeartRateZone? = nil,
        phases: [WorkoutPhase] = [],
        isCompleted: Bool = false,
        completedDate: Date? = nil
    ) {
        self.id = id
        self.week = week
        self.day = day
        self.name = name
        self.description = description
        self.duration = duration
        self.targetHeartRate = targetHeartRate
        self.phases = phases
        self.isCompleted = isCompleted
        self.completedDate = completedDate
    }
}

/// Зона ЧСС для плана (используем существующую HeartRateZone из HeartRateData)
