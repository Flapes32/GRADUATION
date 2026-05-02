//
//  WorkoutPlansManager.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import Foundation
import Combine

/// Менеджер для управления планами тренировок
class WorkoutPlansManager: ObservableObject {
    static let shared = WorkoutPlansManager()
    
    @Published var plans: [WorkoutPlan] = []
    @Published var activePlan: WorkoutPlan?
    
    private let workoutManager = WorkoutManager.shared
    
    private init() {
        loadPlans()
        if plans.isEmpty {
            initializeDefaultPlans()
        }
        updateActivePlan()
    }
    
    /// Инициализировать стандартные планы
    private func initializeDefaultPlans() {
        plans = [
            createBeginnerPlan(),
            createIntermediatePlan(),
            createAdvancedPlan(),
            createEndurancePlan(),
            createStrengthPlan(),
            createSpeedPlan(),
            createRecoveryPlan()
        ]
        savePlans()
    }
    
    /// Создать план для начинающих
    private func createBeginnerPlan() -> WorkoutPlan {
        var workouts: [PlanWorkout] = []
        
        // 4 недели, 3 тренировки в неделю
        for week in 1...4 {
            for day in [1, 3, 5] { // Понедельник, среда, пятница
                workouts.append(PlanWorkout(
                    week: week,
                    day: day,
                    name: "Базовая тренировка \(week) неделя",
                    description: "Разминка 10 мин, рабочий раунд 20 мин, отдых 5 мин",
                    duration: 35 * 60,
                    phases: [.warmup, .active, .rest]
                ))
            }
        }
        
        return WorkoutPlan(
            name: "План для начинающих",
            description: "4-недельный план для тех, кто только начинает заниматься боксом",
            type: .beginner,
            duration: 28,
            workoutsPerWeek: 3,
            totalWeeks: 4,
            workouts: workouts
        )
    }
    
    /// Создать план среднего уровня
    private func createIntermediatePlan() -> WorkoutPlan {
        var workouts: [PlanWorkout] = []
        
        // 6 недель, 4 тренировки в неделю
        for week in 1...6 {
            for day in [1, 3, 5, 6] {
                let intensity = week <= 3 ? "Средняя" : "Высокая"
                workouts.append(PlanWorkout(
                    week: week,
                    day: day,
                    name: "\(intensity) тренировка \(week) неделя",
                    description: "Разминка 10 мин, рабочий раунд 30 мин, спринт 10 мин, отдых 5 мин",
                    duration: 55 * 60,
                    phases: [.warmup, .active, .sprint, .rest]
                ))
            }
        }
        
        return WorkoutPlan(
            name: "План среднего уровня",
            description: "6-недельный план для спортсменов среднего уровня подготовки",
            type: .intermediate,
            duration: 42,
            workoutsPerWeek: 4,
            totalWeeks: 6,
            workouts: workouts
        )
    }
    
    /// Создать план продвинутого уровня
    private func createAdvancedPlan() -> WorkoutPlan {
        var workouts: [PlanWorkout] = []
        
        // 8 недель, 5 тренировок в неделю
        for week in 1...8 {
            for day in [1, 2, 4, 5, 6] {
                workouts.append(PlanWorkout(
                    week: week,
                    day: day,
                    name: "Интенсивная тренировка \(week) неделя",
                    description: "Разминка 15 мин, рабочий раунд 40 мин, спринт 15 мин, отдых 10 мин",
                    duration: 80 * 60,
                    phases: [.warmup, .active, .sprint, .rest]
                ))
            }
        }
        
        return WorkoutPlan(
            name: "План продвинутого уровня",
            description: "8-недельный интенсивный план для опытных спортсменов",
            type: .advanced,
            duration: 56,
            workoutsPerWeek: 5,
            totalWeeks: 8,
            workouts: workouts
        )
    }
    
    /// Создать план на выносливость
    private func createEndurancePlan() -> WorkoutPlan {
        var workouts: [PlanWorkout] = []
        
        // 4 недели, 4 тренировки в неделю
        for week in 1...4 {
            for day in [1, 3, 5, 6] {
                workouts.append(PlanWorkout(
                    week: week,
                    day: day,
                    name: "Тренировка на выносливость \(week) неделя",
                    description: "Длительные рабочие раунды для развития выносливости",
                    duration: 60 * 60,
                    targetHeartRate: HeartRateZone(min: 140, max: 170, name: "Аэробная зона", color: .aerobic),
                    phases: [.warmup, .active, .active, .rest]
                ))
            }
        }
        
        return WorkoutPlan(
            name: "План на выносливость",
            description: "4-недельный план для развития кардио-выносливости",
            type: .endurance,
            duration: 28,
            workoutsPerWeek: 4,
            totalWeeks: 4,
            workouts: workouts
        )
    }
    
    /// Создать план на силу
    private func createStrengthPlan() -> WorkoutPlan {
        var workouts: [PlanWorkout] = []
        
        // 4 недели, 3 тренировки в неделю
        for week in 1...4 {
            for day in [1, 3, 5] {
                workouts.append(PlanWorkout(
                    week: week,
                    day: day,
                    name: "Силовая тренировка \(week) неделя",
                    description: "Короткие интенсивные раунды с акцентом на силу",
                    duration: 45 * 60,
                    targetHeartRate: HeartRateZone(min: 170, max: 190, name: "Анаэробная зона", color: .anaerobic),
                    phases: [.warmup, .sprint, .rest, .sprint, .rest]
                ))
            }
        }
        
        return WorkoutPlan(
            name: "План на силу",
            description: "4-недельный план для развития силы и мощности",
            type: .strength,
            duration: 28,
            workoutsPerWeek: 3,
            totalWeeks: 4,
            workouts: workouts
        )
    }
    
    /// Создать план на скорость
    private func createSpeedPlan() -> WorkoutPlan {
        var workouts: [PlanWorkout] = []
        
        // 4 недели, 4 тренировки в неделю
        for week in 1...4 {
            for day in [1, 3, 5, 6] {
                workouts.append(PlanWorkout(
                    week: week,
                    day: day,
                    name: "Скоростная тренировка \(week) неделя",
                    description: "Множественные спринты для развития скорости",
                    duration: 40 * 60,
                    targetHeartRate: HeartRateZone(min: 180, max: 200, name: "Максимальная зона", color: .maximum),
                    phases: [.warmup, .sprint, .rest, .sprint, .rest, .sprint, .rest]
                ))
            }
        }
        
        return WorkoutPlan(
            name: "План на скорость",
            description: "4-недельный план для развития скорости и реакции",
            type: .speed,
            duration: 28,
            workoutsPerWeek: 4,
            totalWeeks: 4,
            workouts: workouts
        )
    }
    
    /// Создать план восстановления
    private func createRecoveryPlan() -> WorkoutPlan {
        var workouts: [PlanWorkout] = []
        
        // 2 недели, 3 легкие тренировки в неделю
        for week in 1...2 {
            for day in [1, 3, 5] {
                workouts.append(PlanWorkout(
                    week: week,
                    day: day,
                    name: "Восстановительная тренировка \(week) неделя",
                    description: "Легкие тренировки для активного восстановления",
                    duration: 30 * 60,
                    targetHeartRate: HeartRateZone(min: 100, max: 140, name: "Зона восстановления", color: .warmup),
                    phases: [.warmup, .active, .rest]
                ))
            }
        }
        
        return WorkoutPlan(
            name: "План восстановления",
            description: "2-недельный план для активного восстановления после интенсивных тренировок",
            type: .recovery,
            duration: 14,
            workoutsPerWeek: 3,
            totalWeeks: 2,
            workouts: workouts
        )
    }
    
    /// Начать план
    func startPlan(_ plan: WorkoutPlan) {
        var updatedPlan = plan
        updatedPlan.status = .active
        updatedPlan.startDate = Date()
        updatedPlan.endDate = Calendar.current.date(byAdding: .day, value: plan.duration, to: Date())
        updatedPlan.currentWeek = 1
        
        if let index = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[index] = updatedPlan
        } else {
            plans.append(updatedPlan)
        }
        
        activePlan = updatedPlan
        savePlans()
    }
    
    /// Завершить тренировку из плана
    func completeWorkout(_ workout: PlanWorkout) {
        guard var plan = activePlan else { return }
        
        if let workoutIndex = plan.workouts.firstIndex(where: { $0.id == workout.id }) {
            plan.workouts[workoutIndex].isCompleted = true
            plan.workouts[workoutIndex].completedDate = Date()
            
            // Обновляем прогресс плана
            let completedCount = plan.workouts.filter { $0.isCompleted }.count
            plan.progress = Double(completedCount) / Double(plan.workouts.count)
            
            // Проверяем завершение недели
            let currentWeekWorkouts = plan.workouts.filter { $0.week == plan.currentWeek }
            let completedWeekWorkouts = currentWeekWorkouts.filter { $0.isCompleted }
            
            if completedWeekWorkouts.count == currentWeekWorkouts.count && plan.currentWeek < plan.totalWeeks {
                plan.currentWeek += 1
            }
            
            // Проверяем завершение плана
            if plan.progress >= 1.0 {
                plan.status = .completed
            }
            
            activePlan = plan
            
            if let index = plans.firstIndex(where: { $0.id == plan.id }) {
                plans[index] = plan
            }
            
            savePlans()
        }
    }
    
    /// Обновить активный план
    func updateActivePlan() {
        activePlan = plans.first { $0.status == .active }
        
        // Обновляем прогресс активного плана
        if var plan = activePlan {
            let completedCount = plan.workouts.filter { $0.isCompleted }.count
            plan.progress = Double(completedCount) / Double(plan.workouts.count)
            
            if let index = plans.firstIndex(where: { $0.id == plan.id }) {
                plans[index] = plan
                activePlan = plan
            }
        }
    }
    
    /// Получить тренировки на сегодня
    func getTodayWorkouts() -> [PlanWorkout] {
        guard let plan = activePlan else { return [] }
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date()) // 1 = воскресенье, 2 = понедельник...
        let dayOfWeek = today == 1 ? 7 : today - 1 // Преобразуем в 1-7 (пн-вс)
        
        return plan.workouts.filter { workout in
            workout.week == plan.currentWeek && workout.day == dayOfWeek && !workout.isCompleted
        }
    }
    
    // MARK: - Сохранение/Загрузка
    
    private func savePlans() {
        if let encoded = try? JSONEncoder().encode(plans) {
            UserDefaults.standard.set(encoded, forKey: "workoutPlans")
        }
    }
    
    private func loadPlans() {
        if let data = UserDefaults.standard.data(forKey: "workoutPlans"),
           let decoded = try? JSONDecoder().decode([WorkoutPlan].self, from: data) {
            plans = decoded
        }
    }
}
