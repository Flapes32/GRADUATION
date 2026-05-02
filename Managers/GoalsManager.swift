//
//  GoalsManager.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import Foundation
import Combine

/// Менеджер для управления целями и достижениями
class GoalsManager: ObservableObject {
    static let shared = GoalsManager()
    
    @Published var goals: [Goal] = []
    @Published var achievements: [Achievement] = []
    @Published var progressStats: ProgressStats = ProgressStats()
    
    private let workoutManager = WorkoutManager.shared
    
    private init() {
        loadGoals()
        loadAchievements()
        loadProgressStats()
        initializeDefaultAchievements()
        updateAllGoals()
        checkAchievements()
    }
    
    // MARK: - Цели
    
    /// Создать новую цель
    func createGoal(
        title: String,
        description: String,
        type: GoalType,
        targetValue: Double,
        endDate: Date,
        isRecurring: Bool = false
    ) {
        let goal = Goal(
            title: title,
            description: description,
            type: type,
            targetValue: targetValue,
            endDate: endDate,
            isRecurring: isRecurring
        )
        goals.append(goal)
        saveGoals()
    }
    
    /// Обновить прогресс всех целей
    func updateAllGoals() {
        for index in goals.indices {
            updateGoalProgress(at: index)
        }
        saveGoals()
    }
    
    /// Обновить прогресс конкретной цели
    private func updateGoalProgress(at index: Int) {
        guard index < goals.count else { return }
        var goal = goals[index]
        
        let workouts = workoutManager.workoutHistory
        let calendar = Calendar.current
        let now = Date()
        
        // Фильтруем тренировки по периоду цели
        let relevantWorkouts = workouts.filter { workout in
            workout.startDate >= goal.startDate && workout.startDate <= goal.endDate
        }
        
        switch goal.type {
        case .workouts:
            goal.currentValue = Double(relevantWorkouts.count)
            
        case .calories:
            let totalCalories = relevantWorkouts.compactMap { $0.caloriesBurned }.reduce(0, +)
            goal.currentValue = totalCalories
            
        case .duration:
            let totalDuration = relevantWorkouts.compactMap { $0.duration }.reduce(0, +)
            goal.currentValue = totalDuration / 60.0 // В минутах
            
        case .heartRate:
            let allHR = relevantWorkouts.flatMap { $0.heartRateData }
            if !allHR.isEmpty {
                goal.currentValue = allHR.map { $0.value }.reduce(0, +) / Double(allHR.count)
            }
            
        case .recovery:
            let recoveries = relevantWorkouts.compactMap { $0.recoveryTime }
            if !recoveries.isEmpty {
                goal.currentValue = recoveries.reduce(0, +) / Double(recoveries.count) / 60.0
            }
            
        case .consistency:
            // Количество дней с тренировками
            let workoutDays = Set(relevantWorkouts.map { calendar.startOfDay(for: $0.startDate) })
            goal.currentValue = Double(workoutDays.count)
        }
        
        // Проверяем статус
        if goal.currentValue >= goal.targetValue && goal.status == .active {
            goal.status = .completed
            progressStats.goalsCompleted += 1
            addExperience(points: 50)
        } else if goal.endDate < now && goal.status == .active {
            goal.status = .expired
        }
        
        goals[index] = goal
    }
    
    /// Удалить цель
    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        saveGoals()
    }
    
    // MARK: - Достижения
    
    /// Инициализировать стандартные достижения
    private func initializeDefaultAchievements() {
        if achievements.isEmpty {
            achievements = [
                Achievement(
                    title: "Первые шаги",
                    description: "Завершите первую тренировку",
                    icon: "figure.walk",
                    category: .training,
                    requirement: "1 тренировка"
                ),
                Achievement(
                    title: "Стремительный старт",
                    description: "Завершите 5 тренировок",
                    icon: "bolt.fill",
                    category: .training,
                    requirement: "5 тренировок"
                ),
                Achievement(
                    title: "Ветеран",
                    description: "Завершите 25 тренировок",
                    icon: "star.fill",
                    category: .training,
                    requirement: "25 тренировок"
                ),
                Achievement(
                    title: "Мастер",
                    description: "Завершите 50 тренировок",
                    icon: "crown.fill",
                    category: .training,
                    requirement: "50 тренировок"
                ),
                Achievement(
                    title: "Огненная неделя",
                    description: "Сожгите 5000 калорий за неделю",
                    icon: "flame.fill",
                    category: .endurance,
                    requirement: "5000 ккал за неделю"
                ),
                Achievement(
                    title: "Железная воля",
                    description: "Тренируйтесь 7 дней подряд",
                    icon: "link",
                    category: .consistency,
                    requirement: "7 дней подряд"
                ),
                Achievement(
                    title: "Непрерывность",
                    description: "Тренируйтесь 14 дней подряд",
                    icon: "infinity",
                    category: .consistency,
                    requirement: "14 дней подряд"
                ),
                Achievement(
                    title: "Быстрое восстановление",
                    description: "Восстановление менее 5 минут",
                    icon: "arrow.clockwise",
                    category: .recovery,
                    requirement: "Восстановление < 5 мин"
                ),
                Achievement(
                    title: "Пиковая форма",
                    description: "Достигните ЧСС 190+ ударов",
                    icon: "heart.circle.fill",
                    category: .endurance,
                    requirement: "ЧСС > 190"
                ),
                Achievement(
                    title: "Целеустремленный",
                    description: "Выполните 5 целей",
                    icon: "target",
                    category: .milestones,
                    requirement: "5 целей выполнено"
                )
            ]
            saveAchievements()
        }
    }
    
    /// Проверить и обновить достижения
    func checkAchievements() {
        let workouts = workoutManager.workoutHistory
        let calendar = Calendar.current
        
        // Обновляем прогресс достижений
        for index in achievements.indices {
            var achievement = achievements[index]
            
            if achievement.isUnlocked { continue }
            
            switch achievement.title {
            case "Первые шаги":
                achievement.progress = min(1.0, Double(workouts.count) / 1.0)
                if workouts.count >= 1 {
                    unlockAchievement(at: index)
                }
                
            case "Стремительный старт":
                achievement.progress = min(1.0, Double(workouts.count) / 5.0)
                if workouts.count >= 5 {
                    unlockAchievement(at: index)
                }
                
            case "Ветеран":
                achievement.progress = min(1.0, Double(workouts.count) / 25.0)
                if workouts.count >= 25 {
                    unlockAchievement(at: index)
                }
                
            case "Мастер":
                achievement.progress = min(1.0, Double(workouts.count) / 50.0)
                if workouts.count >= 50 {
                    unlockAchievement(at: index)
                }
                
            case "Огненная неделя":
                let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                let weekWorkouts = workouts.filter { $0.startDate >= weekAgo }
                let weekCalories = weekWorkouts.compactMap { $0.caloriesBurned }.reduce(0, +)
                achievement.progress = min(1.0, weekCalories / 5000.0)
                if weekCalories >= 5000 {
                    unlockAchievement(at: index)
                }
                
            case "Железная воля":
                let streak = calculateCurrentStreak()
                achievement.progress = min(1.0, Double(streak) / 7.0)
                if streak >= 7 {
                    unlockAchievement(at: index)
                }
                
            case "Непрерывность":
                let streak = calculateCurrentStreak()
                achievement.progress = min(1.0, Double(streak) / 14.0)
                if streak >= 14 {
                    unlockAchievement(at: index)
                }
                
            case "Быстрое восстановление":
                let fastRecoveries = workouts.filter { workout in
                    if let recovery = workout.recoveryTime {
                        return recovery / 60.0 < 5.0
                    }
                    return false
                }
                achievement.progress = fastRecoveries.isEmpty ? 0 : 1.0
                if !fastRecoveries.isEmpty {
                    unlockAchievement(at: index)
                }
                
            case "Пиковая форма":
                let maxHR = workouts.flatMap { $0.heartRateData }.map { $0.value }.max() ?? 0
                achievement.progress = min(1.0, maxHR / 190.0)
                if maxHR >= 190 {
                    unlockAchievement(at: index)
                }
                
            case "Целеустремленный":
                let completedGoals = goals.filter { $0.status == .completed }.count
                achievement.progress = min(1.0, Double(completedGoals) / 5.0)
                if completedGoals >= 5 {
                    unlockAchievement(at: index)
                }
                
            default:
                break
            }
            
            achievements[index] = achievement
        }
        
        saveAchievements()
        updateProgressStats()
    }
    
    /// Разблокировать достижение
    private func unlockAchievement(at index: Int) {
        guard index < achievements.count else { return }
        var achievement = achievements[index]
        
        if !achievement.isUnlocked {
            achievement.isUnlocked = true
            achievement.unlockedDate = Date()
            achievement.progress = 1.0
            achievements[index] = achievement
            
            progressStats.achievementsUnlocked += 1
            addExperience(points: 100)
        }
    }
    
    // MARK: - Прогресс
    
    /// Обновить статистику прогресса
    func updateProgressStats() {
        let workouts = workoutManager.workoutHistory
        
        progressStats.totalWorkouts = workouts.count
        progressStats.totalCalories = workouts.compactMap { $0.caloriesBurned }.reduce(0, +)
        progressStats.totalDuration = workouts.compactMap { $0.duration }.reduce(0, +)
        progressStats.currentStreak = calculateCurrentStreak()
        progressStats.longestStreak = max(progressStats.longestStreak, progressStats.currentStreak)
        progressStats.achievementsUnlocked = achievements.filter { $0.isUnlocked }.count
        progressStats.goalsCompleted = goals.filter { $0.status == .completed }.count
        
        // Обновляем уровень
        updateLevel()
        
        saveProgressStats()
    }
    
    /// Рассчитать текущую серию тренировок
    private func calculateCurrentStreak() -> Int {
        let workouts = workoutManager.workoutHistory.sorted { $0.startDate > $1.startDate }
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for workout in workouts {
            let workoutDate = calendar.startOfDay(for: workout.startDate)
            if workoutDate == currentDate || workoutDate == calendar.date(byAdding: .day, value: -1, to: currentDate) {
                if workoutDate == calendar.date(byAdding: .day, value: -1, to: currentDate) {
                    currentDate = workoutDate
                    streak += 1
                } else if workoutDate == currentDate {
                    // Уже учтено
                }
            } else {
                break
            }
        }
        
        return streak
    }
    
    /// Добавить опыт
    private func addExperience(points: Int) {
        progressStats.level.experienceCurrent += points
        updateLevel()
        saveProgressStats()
    }
    
    /// Обновить уровень
    private func updateLevel() {
        var level = progressStats.level
        
        // Рассчитываем опыт на основе тренировок
        let baseExperience = progressStats.totalWorkouts * 10
        let caloriesExperience = Int(progressStats.totalCalories / 10)
        let achievementsExperience = progressStats.achievementsUnlocked * 50
        let goalsExperience = progressStats.goalsCompleted * 30
        
        level.experienceCurrent = baseExperience + caloriesExperience + achievementsExperience + goalsExperience
        
        // Определяем уровень и требования
        let levelTitles = [
            (1, "Новичок", 0, 100),
            (2, "Ученик", 100, 250),
            (3, "Боец", 250, 500),
            (4, "Профи", 500, 1000),
            (5, "Мастер", 1000, 2000),
            (6, "Эксперт", 2000, 4000),
            (7, "Легенда", 4000, 8000),
            (8, "Чемпион", 8000, 15000),
            (9, "Икона", 15000, 30000),
            (10, "Бог бокса", 30000, 999999)
        ]
        
        for (lvl, title, required, nextRequired) in levelTitles.reversed() {
            if level.experienceCurrent >= required {
                level.level = lvl
                level.title = title
                level.experienceRequired = required
                level.nextLevelExperience = nextRequired
                break
            }
        }
        
        progressStats.level = level
    }
    
    // MARK: - Сохранение/Загрузка
    
    private func saveGoals() {
        if let encoded = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(encoded, forKey: "goals")
        }
    }
    
    private func loadGoals() {
        if let data = UserDefaults.standard.data(forKey: "goals"),
           let decoded = try? JSONDecoder().decode([Goal].self, from: data) {
            goals = decoded
        }
    }
    
    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "achievements")
        }
    }
    
    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        }
    }
    
    private func saveProgressStats() {
        if let encoded = try? JSONEncoder().encode(progressStats) {
            UserDefaults.standard.set(encoded, forKey: "progressStats")
        }
    }
    
    private func loadProgressStats() {
        if let data = UserDefaults.standard.data(forKey: "progressStats"),
           let decoded = try? JSONDecoder().decode(ProgressStats.self, from: data) {
            progressStats = decoded
        }
    }
}
