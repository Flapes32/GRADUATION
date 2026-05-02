//
//  AnalyticsView.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import SwiftUI
import Charts

/// Экран расширенной аналитики
struct AnalyticsView: View {
    @StateObject private var analyticsManager = AnalyticsManager.shared
    @StateObject private var workoutManager = WorkoutManager.shared
    @StateObject private var goalsManager = GoalsManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Прогнозы производительности
                        ForecastsSection(forecasts: analyticsManager.forecasts)
                        
                        // Тренды
                        TrendsSection(trends: analyticsManager.trends)
                        
                        // Рекомендации
                        RecommendationsSection(recommendations: analyticsManager.getRecommendations())
                        
                        // Сравнительная аналитика
                        ComparisonSection()
                        
                        // Детальная статистика
                        DetailedAnalyticsSection()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Аналитика")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                analyticsManager.generateForecasts()
                analyticsManager.calculateTrends()
            }
        }
    }
}

/// Секция прогнозов
struct ForecastsSection: View {
    let forecasts: [PerformanceForecast]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Прогноз производительности")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            if forecasts.isEmpty {
                Text("Недостаточно данных для прогноза")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(forecasts.prefix(7)) { forecast in
                        ForecastCard(forecast: forecast)
                    }
                }
            }
        }
    }
}

/// Карточка прогноза
struct ForecastCard: View {
    let forecast: PerformanceForecast
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: forecast.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dateString)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(forecast.confidence * 100))% уверенность")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            HStack(spacing: 20) {
                ForecastMetric(icon: "figure.boxing", value: "\(forecast.predictedWorkouts)", label: "тренировок")
                ForecastMetric(icon: "flame.fill", value: String(format: "%.0f", forecast.predictedCalories), label: "ккал")
                ForecastMetric(icon: "heart.fill", value: String(format: "%.0f", forecast.predictedAvgHeartRate), label: "ЧСС")
            }
        }
        .padding()
        .boxingCard()
    }
}

/// Метрика прогноза
struct ForecastMetric: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.yellow)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

/// Секция трендов
struct TrendsSection: View {
    let trends: [TrendData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Тренды")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            if trends.isEmpty {
                Text("Недостаточно данных для анализа трендов")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(trends.suffix(8)) { trend in
                        TrendCard(trend: trend)
                    }
                }
            }
        }
    }
}

/// Карточка тренда
struct TrendCard: View {
    let trend: TrendData
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: trend.date)
    }
    
    var trendIcon: String {
        switch trend.trend {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
    
    var trendColor: Color {
        switch trend.trend {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .yellow
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(dateString)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                HStack(spacing: 16) {
                    TrendMetric(value: "\(trend.workouts)", label: "тренировок")
                    TrendMetric(value: String(format: "%.0f", trend.calories), label: "ккал")
                    TrendMetric(value: String(format: "%.0f", trend.avgHeartRate), label: "ЧСС")
                }
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Image(systemName: trendIcon)
                    .font(.system(size: 20))
                    .foregroundColor(trendColor)
                
                Text(trend.trend.rawValue)
                    .font(.caption)
                    .foregroundColor(trendColor)
            }
        }
        .padding()
        .boxingCard()
    }
}

/// Метрика тренда
struct TrendMetric: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

/// Секция рекомендаций
struct RecommendationsSection: View {
    let recommendations: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Рекомендации")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            if recommendations.isEmpty {
                Text("Все показатели в норме!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(recommendations.enumerated()), id: \.offset) { index, recommendation in
                        RecommendationCard(text: recommendation, index: index)
                    }
                }
            }
        }
    }
}

/// Карточка рекомендации
struct RecommendationCard: View {
    let text: String
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.yellow)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding()
        .boxingCard()
    }
}

/// Секция сравнения
struct ComparisonSection: View {
    @StateObject private var workoutManager = WorkoutManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Сравнение периодов")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            let workouts = workoutManager.workoutHistory
            let calendar = Calendar.current
            let now = Date()
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: weekAgo) ?? now
            
            let thisWeek = workouts.filter { $0.startDate >= weekAgo }
            let lastWeek = workouts.filter { $0.startDate >= twoWeeksAgo && $0.startDate < weekAgo }
            
            ComparisonCard(
                title: "Эта неделя",
                workouts: thisWeek.count,
                calories: thisWeek.compactMap { $0.caloriesBurned }.reduce(0, +),
                lastTitle: "Прошлая неделя",
                lastWorkouts: lastWeek.count,
                lastCalories: lastWeek.compactMap { $0.caloriesBurned }.reduce(0, +)
            )
        }
    }
}

/// Карточка сравнения
struct ComparisonCard: View {
    let title: String
    let workouts: Int
    let calories: Double
    let lastTitle: String
    let lastWorkouts: Int
    let lastCalories: Double
    
    var workoutsChange: Double {
        guard lastWorkouts > 0 else { return 0 }
        return ((Double(workouts) - Double(lastWorkouts)) / Double(lastWorkouts)) * 100
    }
    
    var caloriesChange: Double {
        guard lastCalories > 0 else { return 0 }
        return ((calories - lastCalories) / lastCalories) * 100
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 16) {
                        ComparisonMetric(value: "\(workouts)", label: "тренировок", change: workoutsChange)
                        ComparisonMetric(value: String(format: "%.0f", calories), label: "ккал", change: caloriesChange)
                    }
                }
                
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lastTitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 16) {
                        Text("\(lastWorkouts) тренировок")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text(String(format: "%.0f ккал", lastCalories))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .boxingCard()
    }
}

/// Метрика сравнения
struct ComparisonMetric: View {
    let value: String
    let label: String
    let change: Double
    
    var changeIcon: String {
        if change > 0 { return "arrow.up" }
        if change < 0 { return "arrow.down" }
        return "minus"
    }
    
    var changeColor: Color {
        if change > 0 { return .green }
        if change < 0 { return .red }
        return .yellow
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                
                if abs(change) > 0.1 {
                    HStack(spacing: 2) {
                        Image(systemName: changeIcon)
                            .font(.caption2)
                        Text(String(format: "%.0f%%", abs(change)))
                            .font(.caption2)
                    }
                    .foregroundColor(changeColor)
                }
            }
        }
    }
}

/// Секция детальной аналитики
struct DetailedAnalyticsSection: View {
    @StateObject private var workoutManager = WorkoutManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Детальная аналитика")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            let workouts = workoutManager.workoutHistory
            
            AnalyticsDetailCard(
                title: "Средняя интенсивность",
                value: calculateAvgIntensity(workouts: workouts),
                subtitle: "на основе ЧСС"
            )
            
            AnalyticsDetailCard(
                title: "Среднее время восстановления",
                value: calculateAvgRecovery(workouts: workouts),
                subtitle: "минут"
            )
            
            AnalyticsDetailCard(
                title: "Консистентность",
                value: calculateConsistency(workouts: workouts),
                subtitle: "дней с тренировками"
            )
        }
    }
    
    private func calculateAvgIntensity(workouts: [WorkoutSession]) -> String {
        let allHR = workouts.flatMap { $0.heartRateData }
        guard !allHR.isEmpty else { return "Н/Д" }
        let avg = allHR.map { $0.value }.reduce(0, +) / Double(allHR.count)
        return String(format: "%.0f уд/мин", avg)
    }
    
    private func calculateAvgRecovery(workouts: [WorkoutSession]) -> String {
        let recoveries = workouts.compactMap { $0.recoveryTime }
        guard !recoveries.isEmpty else { return "Н/Д" }
        let avg = recoveries.reduce(0, +) / Double(recoveries.count) / 60.0
        return String(format: "%.1f", avg)
    }
    
    private func calculateConsistency(workouts: [WorkoutSession]) -> String {
        let calendar = Calendar.current
        let workoutDays = Set(workouts.map { calendar.startOfDay(for: $0.startDate) })
        return "\(workoutDays.count)"
    }
}

/// Карточка детальной аналитики
struct AnalyticsDetailCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding()
        .boxingCard()
    }
}

#Preview {
    AnalyticsView()
}
