//
//  WorkoutManager.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import Foundation
import Combine

/// Менеджер для управления тренировками
class WorkoutManager: ObservableObject {
    static let shared = WorkoutManager()
    
    @Published var currentSession: WorkoutSession?
    @Published var workoutHistory: [WorkoutSession] = []
    @Published var currentPhase: WorkoutPhase = .warmup
    @Published var peakLoadCount: Int = 0
    @Published var heartRateRecovery: HeartRateRecovery?
    @Published var recoveryStatus: RecoveryStatus = .ready
    
    private let healthKitManager = HealthKitManager.shared
    private let lactatePredictor = LactatePredictor.shared
    
    private var heartRateAtRestStart: Double?
    private var restStartTime: Date?
    private var maxHeartRate: Double = 200.0
    
    private init() {
        loadWorkoutHistory()
        
        // Если истории нет или очень мало данных, загружаем тестовые данные
        // Также перезагружаем, если данных слишком много (старая версия с 57 тренировками)
        // Или если все тренировки имеют одинаковое время (старая версия)
        let hasSameTime = workoutHistory.count > 1 && workoutHistory.allSatisfy { workout in
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: workout.startDate)
            return hour == calendar.component(.hour, from: workoutHistory.first!.startDate)
        }
        
        if workoutHistory.isEmpty || workoutHistory.count < 5 || workoutHistory.count > 15 || hasSameTime {
            // Принудительно очищаем старые данные
            UserDefaults.standard.removeObject(forKey: "workoutHistory")
            UserDefaults.standard.synchronize()
            workoutHistory = []
            loadTestData()
        }
    }
    
    /// Загрузить тестовые данные
    private func loadTestData() {
        // Очищаем старые данные перед загрузкой новых
        workoutHistory = []
        UserDefaults.standard.removeObject(forKey: "workoutHistory")
        UserDefaults.standard.synchronize() // Принудительно сохраняем
        
        let testWorkouts = TestDataManager.shared.generateTestWorkouts()
        workoutHistory = testWorkouts
        saveWorkoutHistory()
        print("✅ Загружено \(testWorkouts.count) тестовых тренировок")
        print("📅 Время тренировок: \(testWorkouts.map { DateFormatter.localizedString(from: $0.startDate, dateStyle: .none, timeStyle: .short) })")
    }
    
    /// Принудительно перезагрузить тестовые данные (для отладки)
    func reloadTestData() {
        // Очищаем старые данные
        UserDefaults.standard.removeObject(forKey: "workoutHistory")
        workoutHistory = []
        loadTestData()
    }
    
    /// Начать новую тренировку
    func startWorkout() {
        let session = WorkoutSession()
        currentSession = session
        currentPhase = .warmup
        peakLoadCount = 0
        heartRateRecovery = nil
        recoveryStatus = .ready
        
        healthKitManager.startHeartRateMonitoring()
        lactatePredictor.startMotionMonitoring()
        lactatePredictor.reset()
    }
    
    /// Завершить тренировку
    func endWorkout() {
        guard var session = currentSession else { return }
        
        session.endDate = Date()
        
        // Рассчитываем время восстановления лактата
        if let peakLactate = session.lactateData.max(by: { $0.predictedValue < $1.predictedValue }) {
            session.peakLactate = peakLactate.predictedValue
            
            // Находим время, когда лактат вернулся к норме
            if let recoveryTime = calculateLactateRecoveryTime(peakLactate: peakLactate, session: session) {
                session.recoveryTime = recoveryTime
            }
        }
        
        // Рассчитываем калории
        if let duration = session.duration {
            let avgHR = session.heartRateData.isEmpty ? 150.0 : 
                session.heartRateData.map { $0.value }.reduce(0, +) / Double(session.heartRateData.count)
            
            // Базовый расход: 8 ккал/мин при ЧСС 120, увеличивается с ЧСС
            let baseCaloriesPerMin = 8.0
            let hrMultiplier = max(1.0, avgHR / 120.0)
            let caloriesPerMin = baseCaloriesPerMin * hrMultiplier
            
            session.caloriesBurned = (duration / 60.0) * caloriesPerMin
        }
        
        workoutHistory.append(session)
        saveWorkoutHistory()
        
        currentSession = nil
        healthKitManager.stopHeartRateMonitoring()
        lactatePredictor.stopMotionMonitoring()
    }
    
    /// Обновить данные тренировки
    func updateWorkoutData(heartRate: Double?) {
        guard var session = currentSession, let hr = heartRate else { return }
        
        // Добавляем данные ЧСС
        let hrData = HeartRateData(value: hr, timestamp: Date(), workoutSessionId: session.id)
        session.heartRateData.append(hrData)
        
        // Проверяем пиковые нагрузки (ЧСС > 95% от максимума)
        let percentageOfMax = hr / maxHeartRate
        if percentageOfMax >= 0.95 {
            let peakLoad = PeakLoad(
                heartRate: hr,
                percentageOfMax: percentageOfMax,
                workoutSessionId: session.id
            )
            session.peakLoads.append(peakLoad)
            peakLoadCount = session.peakLoads.count
        }
        
        // Обновляем прогноз лактата
        let isRest = currentPhase == .rest
        lactatePredictor.updateLactatePrediction(heartRate: hr, isRestPeriod: isRest)
        
        // Добавляем данные лактата
        let lactateData = LactateData(
            predictedValue: lactatePredictor.currentLactateLevel,
            timestamp: Date(),
            workoutSessionId: session.id
        )
        session.lactateData.append(lactateData)
        
        currentSession = session
    }
    
    /// Начать период отдыха
    func startRestPeriod() {
        currentPhase = .rest
        heartRateAtRestStart = healthKitManager.currentHeartRate
        restStartTime = Date()
    }
    
    /// Обновить данные восстановления во время отдыха
    func updateRecoveryData() {
        guard let restStart = restStartTime,
              let initialHR = heartRateAtRestStart,
              let currentHR = healthKitManager.currentHeartRate else { return }
        
        let elapsed = Date().timeIntervalSince(restStart)
        
        // Через 30 секунд рассчитываем скорость падения ЧСС
        if elapsed >= 30.0 && elapsed < 35.0 {
            let recovery = HeartRateRecovery(
                initialHeartRate: initialHR,
                heartRateAfter30Seconds: currentHR
            )
            heartRateRecovery = recovery
            
            // Обновляем прогноз лактата с учетом восстановления
            lactatePredictor.updateLactatePrediction(
                heartRate: currentHR,
                recoveryRate: recovery.dropRate,
                isRestPeriod: true
            )
            
            // Определяем статус восстановления
            recoveryStatus = calculateRecoveryStatus(
                recoveryRate: recovery.dropRate,
                lactateLevel: lactatePredictor.currentLactateLevel
            )
        }
    }
    
    /// Рассчитать статус восстановления
    private func calculateRecoveryStatus(recoveryRate: Double, lactateLevel: Double) -> RecoveryStatus {
        // Быстрое восстановление ЧСС (>20 ударов за 30 сек) и низкий лактат
        if recoveryRate >= 20.0 && lactateLevel <= 0.3 {
            return .ready
        }
        // Среднее восстановление или умеренный лактат
        else if recoveryRate >= 10.0 && lactateLevel <= 0.6 {
            return .partial
        }
        // Медленное восстановление или высокий лактат
        else {
            return .risk
        }
    }
    
    /// Рассчитать время восстановления лактата
    private func calculateLactateRecoveryTime(peakLactate: LactateData, session: WorkoutSession) -> TimeInterval? {
        // Находим время, когда лактат упал до нормального уровня (< 0.3)
        let normalThreshold = 0.3
        
        for lactateData in session.lactateData.reversed() {
            if lactateData.predictedValue <= normalThreshold {
                return lactateData.timestamp.timeIntervalSince(peakLactate.timestamp)
            }
        }
        
        return nil
    }
    
    /// Изменить фазу тренировки
    func changePhase(_ phase: WorkoutPhase) {
        currentPhase = phase
        if var session = currentSession {
            session.phases.append(phase)
            currentSession = session
        }
    }
    
    /// Установить максимальный ЧСС
    func setMaxHeartRate(_ maxHR: Double) {
        maxHeartRate = maxHR
        lactatePredictor.setMaxHeartRate(maxHR)
    }
    
    /// Сохранить историю тренировок
    private func saveWorkoutHistory() {
        if let encoded = try? JSONEncoder().encode(workoutHistory) {
            UserDefaults.standard.set(encoded, forKey: "workoutHistory")
        }
    }
    
    /// Загрузить историю тренировок
    private func loadWorkoutHistory() {
        if let data = UserDefaults.standard.data(forKey: "workoutHistory"),
           let decoded = try? JSONDecoder().decode([WorkoutSession].self, from: data) {
            workoutHistory = decoded
        }
    }
}

