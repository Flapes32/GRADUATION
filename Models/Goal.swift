//
//  Goal.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import Foundation

/// Тип цели
enum GoalType: String, Codable, CaseIterable {
    case workouts = "Тренировки"
    case calories = "Калории"
    case duration = "Время"
    case heartRate = "ЧСС"
    case recovery = "Восстановление"
    case consistency = "Регулярность"
}

/// Статус цели
enum GoalStatus: String, Codable {
    case active = "Активна"
    case completed = "Выполнена"
    case expired = "Просрочена"
    case paused = "Приостановлена"
}

/// Цель пользователя
struct Goal: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var type: GoalType
    var targetValue: Double
    var currentValue: Double
    var startDate: Date
    var endDate: Date
    var status: GoalStatus
    var isRecurring: Bool // Повторяющаяся цель (например, еженедельная)
    
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(1.0, currentValue / targetValue)
    }
    
    var isCompleted: Bool {
        return currentValue >= targetValue && status == .active
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        type: GoalType,
        targetValue: Double,
        currentValue: Double = 0,
        startDate: Date = Date(),
        endDate: Date,
        status: GoalStatus = .active,
        isRecurring: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.isRecurring = isRecurring
    }
}

/// Достижение пользователя
struct Achievement: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let requirement: String
    var isUnlocked: Bool
    var unlockedDate: Date?
    var progress: Double // 0.0 - 1.0
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        icon: String,
        category: AchievementCategory,
        requirement: String,
        isUnlocked: Bool = false,
        unlockedDate: Date? = nil,
        progress: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
        self.requirement = requirement
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
        self.progress = progress
    }
}

/// Категория достижения
enum AchievementCategory: String, Codable, CaseIterable {
    case training = "Тренировки"
    case endurance = "Выносливость"
    case consistency = "Регулярность"
    case recovery = "Восстановление"
    case milestones = "Достижения"
    case special = "Особые"
}
