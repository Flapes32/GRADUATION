//
//  TestDataManager.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import Foundation

/// Менеджер для генерации тестовых данных
class TestDataManager {
    static let shared = TestDataManager()
    
    private init() {}
    
    /// Генерирует тестовые данные тренировок
    func generateTestWorkouts() -> [WorkoutSession] {
        let calendar = Calendar.current
        var workouts: [WorkoutSession] = []
        
        // Генерируем ровно 10 тренировок с разницей в 3 дня
        let targetWorkouts = 10
        var currentDay = 0
        
        for i in 0..<targetWorkouts {
            // Каждая тренировка через 3 дня от предыдущей
            guard let baseDate = calendar.date(byAdding: .day, value: -currentDay, to: Date()) else { break }
            
            // Разное время тренировок для естественности
            // Утро: 6-9, День: 12-15, Вечер: 17-20
            // Используем комбинацию индекса и случайности для разнообразия
            let timeSlot = i % 3
            let hour: Int
            switch timeSlot {
            case 0: // Утро
                hour = Int.random(in: 6...9)
            case 1: // День
                hour = Int.random(in: 12...15)
            default: // Вечер
                hour = Int.random(in: 17...20)
            }
            
            // Добавляем больше вариативности в минуты
            let minute = Int.random(in: 0...59)
            
            // Создаем дату с правильным временем
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.second = 0
            
            guard let date = calendar.date(from: dateComponents) else {
                currentDay += 3
                continue
            }
            
            // Основная тренировка
            let workout = generateWorkoutForDate(date)
            workouts.append(workout)
            
            // Следующая тренировка через 3 дня
            currentDay += 3
        }
        
        return workouts.sorted { $0.startDate > $1.startDate }
    }
    
    /// Генерирует одну тренировку для даты
    private func generateWorkoutForDate(_ date: Date) -> WorkoutSession {
        let calendar = Calendar.current
        var session = WorkoutSession(
            startDate: date,
            endDate: calendar.date(byAdding: .minute, value: Int.random(in: 30...90), to: date)
        )
        
        // Генерируем фазы
        session.phases = [.warmup, .active, .active, .sprint, .rest, .active, .rest]
        
        // Генерируем данные ЧСС с более реалистичными значениями
        let duration = session.duration ?? 3600
        let dataPoints = Int(duration / 5) // Данные каждые 5 секунд
        
        // Базовый ЧСС зависит от фазы тренировки
        var currentBaseHR: Double = 100.0 // Начальный ЧСС
        
        for i in 0..<dataPoints {
            let timestamp = date.addingTimeInterval(TimeInterval(i * 5))
            
            // Определяем текущую фазу
            let phaseIndex = min(i / max(dataPoints / session.phases.count, 1), session.phases.count - 1)
            let currentPhase = session.phases[phaseIndex]
            
            // Базовый ЧСС в зависимости от фазы
            switch currentPhase {
            case .warmup:
                currentBaseHR = min(140, currentBaseHR + 2)
            case .active:
                currentBaseHR = min(170, currentBaseHR + 3)
            case .sprint:
                currentBaseHR = min(190, currentBaseHR + 5)
            case .rest:
                currentBaseHR = max(100, currentBaseHR - 4)
            }
            
            let heartRate = currentBaseHR + Double.random(in: -8...8)
            
            session.heartRateData.append(
                HeartRateData(
                    value: heartRate,
                    timestamp: timestamp,
                    workoutSessionId: session.id
                )
            )
        }
        
        // Генерируем данные лактата
        var currentLactate: Double = 0.0
        let phasesCount = session.phases.count
        let pointsPerPhase = dataPoints / phasesCount
        
        for i in 0..<dataPoints {
            let timestamp = date.addingTimeInterval(TimeInterval(i * 5))
            
            // Лактат растет во время активности, падает во время отдыха
            let phaseIndex = min(i / max(pointsPerPhase, 1), phasesCount - 1)
            let phase = session.phases[phaseIndex]
            
            if phase == .rest {
                currentLactate = max(0.0, currentLactate - 0.02)
            } else {
                // Лактат растет по-разному в зависимости от фазы
                let increase: Double
                switch phase {
                case .warmup:
                    increase = Double.random(in: 0.005...0.015) // Медленный рост
                case .active:
                    increase = Double.random(in: 0.01...0.03) // Средний рост
                case .sprint:
                    increase = Double.random(in: 0.02...0.05) // Быстрый рост
                case .rest:
                    increase = -0.02 // Падение
                }
                currentLactate = min(0.95, currentLactate + increase) // Максимум 95%, не 100%
            }
            
            session.lactateData.append(
                LactateData(
                    predictedValue: currentLactate,
                    timestamp: timestamp,
                    workoutSessionId: session.id
                )
            )
        }
        
        // Генерируем пиковые нагрузки (ЧСС > 95% от максимума, т.е. > 190)
        let peakCount = Int.random(in: 5...12)
        let highHRData = session.heartRateData.filter { $0.value > 190 }
        
        if !highHRData.isEmpty {
            for _ in 0..<min(peakCount, highHRData.count) {
                let randomHR = highHRData.randomElement()!
                session.peakLoads.append(
                    PeakLoad(
                        heartRate: randomHR.value,
                        percentageOfMax: randomHR.value / 200.0,
                        workoutSessionId: session.id
                    )
                )
            }
        } else {
            // Если нет высокого ЧСС, создаем несколько пиковых нагрузок искусственно
            for _ in 0..<peakCount {
                let randomIndex = Int.random(in: 0..<session.heartRateData.count)
                let hrData = session.heartRateData[randomIndex]
                let peakHR = max(hrData.value, 190.0) // Минимум 190 для пиковой нагрузки
                
                session.peakLoads.append(
                    PeakLoad(
                        heartRate: peakHR,
                        percentageOfMax: peakHR / 200.0,
                        workoutSessionId: session.id
                    )
                )
            }
        }
        
        // Устанавливаем пиковый лактат
        if let maxLactate = session.lactateData.max(by: { $0.predictedValue < $1.predictedValue }) {
            session.peakLactate = maxLactate.predictedValue
            
            // Время восстановления (от пика до нормы < 0.3)
            if let recoveryIndex = session.lactateData.firstIndex(where: { 
                $0.timestamp > maxLactate.timestamp && $0.predictedValue <= 0.3 
            }) {
                let recoveryData = session.lactateData[recoveryIndex]
                session.recoveryTime = recoveryData.timestamp.timeIntervalSince(maxLactate.timestamp)
            } else {
                // Если не нашли точку восстановления, устанавливаем примерное время
                // Время восстановления зависит от пикового лактата
                let estimatedRecovery = maxLactate.predictedValue * 300 // Примерно 5 минут на единицу лактата
                session.recoveryTime = estimatedRecovery
            }
        } else {
            // Если нет данных лактата, устанавливаем реалистичное значение
            // Большинство тренировок имеют лактат 40-70%, редко выше
            let random = Double.random(in: 0...1)
            if random < 0.6 {
                // 60% тренировок - средний лактат
                session.peakLactate = Double.random(in: 0.4...0.65)
            } else if random < 0.9 {
                // 30% тренировок - высокий лактат
                session.peakLactate = Double.random(in: 0.65...0.85)
            } else {
                // 10% тренировок - очень высокий лактат
                session.peakLactate = Double.random(in: 0.85...0.95)
            }
            session.recoveryTime = session.peakLactate! * 300 // Примерно 5 минут на единицу лактата
        }
        
        // Рассчитываем калории: примерно 10-12 ккал/мин для интенсивной тренировки
        // Учитываем средний ЧСС для более точного расчета
        if let duration = session.duration {
            let avgHR = session.heartRateData.isEmpty ? 150.0 : 
                session.heartRateData.map { $0.value }.reduce(0, +) / Double(session.heartRateData.count)
            
            // Базовый расход: 8 ккал/мин при ЧСС 120, увеличивается с ЧСС
            let baseCaloriesPerMin = 8.0
            let hrMultiplier = max(1.0, avgHR / 120.0) // Множитель в зависимости от ЧСС
            let caloriesPerMin = baseCaloriesPerMin * hrMultiplier
            
            let calculatedCalories = (duration / 60.0) * caloriesPerMin
            // Обеспечиваем минимум 400 калорий и максимум 1200, среднее около 800
            session.caloriesBurned = max(400, min(1200, calculatedCalories))
        } else {
            // Если нет длительности, устанавливаем среднее значение
            session.caloriesBurned = 800.0
        }
        
        return session
    }
}

