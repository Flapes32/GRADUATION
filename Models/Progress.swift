//
//  Progress.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import Foundation

/// Уровень пользователя
struct UserLevel: Codable {
    var level: Int
    var title: String
    var experienceRequired: Int
    var experienceCurrent: Int
    var nextLevelExperience: Int
    
    var progress: Double {
        guard nextLevelExperience > experienceRequired else { return 1.0 }
        let currentProgress = experienceCurrent - experienceRequired
        let totalNeeded = nextLevelExperience - experienceRequired
        return min(1.0, Double(currentProgress) / Double(totalNeeded))
    }
    
    var experienceToNext: Int {
        return max(0, nextLevelExperience - experienceCurrent)
    }
    
    init(
        level: Int = 1,
        title: String = "Новичок",
        experienceRequired: Int = 0,
        experienceCurrent: Int = 0,
        nextLevelExperience: Int = 100
    ) {
        self.level = level
        self.title = title
        self.experienceRequired = experienceRequired
        self.experienceCurrent = experienceCurrent
        self.nextLevelExperience = nextLevelExperience
    }
}

/// Статистика прогресса
struct ProgressStats: Codable {
    var totalWorkouts: Int
    var totalCalories: Double
    var totalDuration: TimeInterval
    var currentStreak: Int // Дней подряд
    var longestStreak: Int
    var achievementsUnlocked: Int
    var goalsCompleted: Int
    var level: UserLevel
    
    init(
        totalWorkouts: Int = 0,
        totalCalories: Double = 0,
        totalDuration: TimeInterval = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        achievementsUnlocked: Int = 0,
        goalsCompleted: Int = 0,
        level: UserLevel = UserLevel()
    ) {
        self.totalWorkouts = totalWorkouts
        self.totalCalories = totalCalories
        self.totalDuration = totalDuration
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.achievementsUnlocked = achievementsUnlocked
        self.goalsCompleted = goalsCompleted
        self.level = level
    }
}

/// Прогноз производительности
struct PerformanceForecast: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let predictedWorkouts: Int
    let predictedCalories: Double
    let predictedAvgHeartRate: Double
    let predictedRecoveryTime: Double
    let confidence: Double // 0.0 - 1.0
    
    init(
        date: Date,
        predictedWorkouts: Int = 0,
        predictedCalories: Double = 0,
        predictedAvgHeartRate: Double = 0,
        predictedRecoveryTime: Double = 0,
        confidence: Double = 0.5
    ) {
        self.date = date
        self.predictedWorkouts = predictedWorkouts
        self.predictedCalories = predictedCalories
        self.predictedAvgHeartRate = predictedAvgHeartRate
        self.predictedRecoveryTime = predictedRecoveryTime
        self.confidence = confidence
    }
}
