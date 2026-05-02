//
//  AnalyticsManager.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import Foundation
import Combine

/// Менеджер для расширенной аналитики и прогнозов
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    @Published var forecasts: [PerformanceForecast] = []
    @Published var trends: [TrendData] = []
    
    private let workoutManager = WorkoutManager.shared
    private let goalsManager = GoalsManager.shared
    
    private init() {
        generateForecasts()
        calculateTrends()
    }
    
    /// Генерировать прогнозы производительности
    func generateForecasts() {
        let workouts = workoutManager.workoutHistory
        guard !workouts.isEmpty else { return }
        
        var newForecasts: [PerformanceForecast] = []
        let calendar = Calendar.current
        
        // Прогноз на следующие 7 дней
        for dayOffset in 1...7 {
            let forecastDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
            
            // Простой прогноз на основе средних значений
            let avgWorkoutsPerWeek = Double(workouts.count) / max(1.0, Double(workouts.count > 0 ? 14 : 1))
            let predictedWorkouts = Int(avgWorkoutsPerWeek * Double(dayOffset) / 7.0)
            
            let avgCalories = workouts.compactMap { $0.caloriesBurned }.reduce(0, +) / Double(workouts.count)
            let predictedCalories = avgCalories * Double(predictedWorkouts)
            
            let allHR = workouts.flatMap { $0.heartRateData }
            let avgHR = allHR.isEmpty ? 150.0 : allHR.map { $0.value }.reduce(0, +) / Double(allHR.count)
            
            let recoveries = workouts.compactMap { $0.recoveryTime }
            let avgRecovery = recoveries.isEmpty ? 5.0 : recoveries.reduce(0, +) / Double(recoveries.count) / 60.0
            
            // Уверенность снижается с увеличением периода прогноза
            let confidence = max(0.3, 1.0 - (Double(dayOffset) * 0.1))
            
            let forecast = PerformanceForecast(
                date: forecastDate,
                predictedWorkouts: predictedWorkouts,
                predictedCalories: predictedCalories,
                predictedAvgHeartRate: avgHR,
                predictedRecoveryTime: avgRecovery,
                confidence: confidence
            )
            
            newForecasts.append(forecast)
        }
        
        forecasts = newForecasts
    }
    
    /// Рассчитать тренды
    func calculateTrends() {
        let workouts = workoutManager.workoutHistory.sorted { $0.startDate < $1.startDate }
        guard !workouts.isEmpty else { return }
        
        var trendData: [TrendData] = []
        let calendar = Calendar.current
        
        // Группируем по неделям
        var weeklyData: [Date: (workouts: Int, calories: Double, avgHR: Double)] = [:]
        
        for workout in workouts {
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.startDate)) ?? workout.startDate
            
            let existing = weeklyData[weekStart] ?? (0, 0.0, 0.0)
            let calories = workout.caloriesBurned ?? 0
            let avgHR = workout.heartRateData.isEmpty ? 0.0 :
                workout.heartRateData.map { $0.value }.reduce(0, +) / Double(workout.heartRateData.count)
            
            weeklyData[weekStart] = (
                existing.workouts + 1,
                existing.calories + calories,
                existing.avgHR > 0 ? (existing.avgHR + avgHR) / 2.0 : avgHR
            )
        }
        
        for (date, data) in weeklyData.sorted(by: { $0.key < $1.key }) {
            let trend = TrendData(
                date: date,
                workouts: data.workouts,
                calories: data.calories,
                avgHeartRate: data.avgHR,
                trend: .stable // Можно улучшить расчет тренда
            )
            trendData.append(trend)
        }
        
        trends = trendData
    }
    
    /// Получить рекомендации на основе аналитики
    func getRecommendations() -> [String] {
        var recommendations: [String] = []
        let workouts = workoutManager.workoutHistory
        
        // Анализ регулярности
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentWorkouts = workouts.filter { $0.startDate >= weekAgo }
        
        if recentWorkouts.count < 3 {
            recommendations.append("Рекомендуется увеличить частоту тренировок до 3-4 раз в неделю")
        }
        
        // Анализ восстановления
        let recentRecoveries = recentWorkouts.compactMap { $0.recoveryTime }
        if !recentRecoveries.isEmpty {
            let avgRecovery = recentRecoveries.reduce(0, +) / Double(recentRecoveries.count) / 60.0
            if avgRecovery > 10 {
                recommendations.append("Время восстановления увеличено. Рекомендуется больше отдыха между тренировками")
            }
        }
        
        // Анализ интенсивности
        let allHR = recentWorkouts.flatMap { $0.heartRateData }
        if !allHR.isEmpty {
            let maxHR = allHR.map { $0.value }.max() ?? 0
            if maxHR < 160 {
                recommendations.append("Интенсивность тренировок можно увеличить для лучших результатов")
            }
        }
        
        // Анализ прогресса
        if trends.count >= 2 {
            let lastWeek = trends[trends.count - 1]
            let previousWeek = trends[trends.count - 2]
            
            if lastWeek.calories < previousWeek.calories {
                recommendations.append("Заметно снижение активности. Рекомендуется вернуться к предыдущему уровню")
            }
        }
        
        return recommendations
    }
}

/// Данные тренда
struct TrendData: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let workouts: Int
    let calories: Double
    let avgHeartRate: Double
    let trend: TrendDirection
}

/// Направление тренда
enum TrendDirection: String, Codable {
    case increasing = "Рост"
    case decreasing = "Снижение"
    case stable = "Стабильно"
}
