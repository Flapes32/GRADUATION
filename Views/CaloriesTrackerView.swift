//
//  CaloriesTrackerView.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import SwiftUI
import Charts

/// Экран трекера калорий
struct CaloriesTrackerView: View {
    @StateObject private var workoutManager = WorkoutManager.shared
    @State private var selectedPeriod: TimePeriod = .today
    
    enum TimePeriod: String, CaseIterable {
        case today = "Сегодня"
        case week = "Неделя"
        case month = "Месяц"
    }
    
    // Демонстрационные данные для наглядности
    @State private var dailyGoal: Double = 2000.0 // Дневная норма калорий
    @State private var todayCalories: Double = 0.0
    
    var filteredWorkouts: [WorkoutSession] {
        let calendar = Calendar.current
        let now = Date()
        let cutoff: Date
        
        switch selectedPeriod {
        case .today:
            cutoff = calendar.startOfDay(for: now)
        case .week:
            cutoff = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            cutoff = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        }
        
        return workoutManager.workoutHistory.filter { $0.startDate >= cutoff }
    }
    
    var totalCalories: Double {
        let calories = filteredWorkouts.compactMap { $0.caloriesBurned }.reduce(0, +)
        // Если нет данных, показываем демо-значение
        if calories == 0 && selectedPeriod == .today {
            return todayCalories
        }
        return calories
    }
    
    var averageCalories: Double {
        let days = selectedPeriod == .today ? 1 : (selectedPeriod == .week ? 7 : 30)
        return totalCalories / Double(days)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Переключатель периода
                        CaloriesPeriodSelector(selectedPeriod: $selectedPeriod)
                        
                        // Главная карточка с калориями
                        MainCaloriesCard(
                            calories: totalCalories,
                            goal: dailyGoal,
                            period: selectedPeriod
                        )
                        
                        // Статистика
                        CaloriesStatsCard(
                            total: totalCalories,
                            average: averageCalories,
                            workouts: filteredWorkouts.count,
                            period: selectedPeriod
                        )
                        
                        // График калорий
                        CaloriesChartCard(workouts: filteredWorkouts, period: selectedPeriod)
                        
                        // Топ тренировок по калориям
                        TopWorkoutsCard(workouts: filteredWorkouts)
                        
                        // Детальная информация
                        DetailedCaloriesInfo(workouts: filteredWorkouts, period: selectedPeriod)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Трекер калорий")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                initializeDemoData()
            }
        }
    }
    
    /// Инициализация демонстрационных данных
    private func initializeDemoData() {
        // Генерируем демо-калории для сегодня
        todayCalories = Double.random(in: 600...1200)
        
        // Обновляем каждые 5 секунд для наглядности
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            // Небольшое случайное изменение
            todayCalories = max(400, min(1500, todayCalories + Double.random(in: -20...20)))
        }
    }
}

/// Переключатель периода
struct CaloriesPeriodSelector: View {
    @Binding var selectedPeriod: CaloriesTrackerView.TimePeriod
    
    var body: some View {
        Picker("Период", selection: $selectedPeriod) {
            ForEach(CaloriesTrackerView.TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
}

/// Главная карточка с калориями
struct MainCaloriesCard: View {
    let calories: Double
    let goal: Double
    let period: CaloriesTrackerView.TimePeriod
    
    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, calories / goal)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Заголовок
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(period == .today ? "Сожжено сегодня" : "Всего сожжено")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Большое число калорий
            VStack(spacing: 8) {
                Text("\(Int(calories))")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("ккал")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Прогресс-бар (только для сегодня)
            if period == .today {
                VStack(spacing: 8) {
                    HStack {
                        Text("Цель: \(Int(goal)) ккал")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Фон
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 12)
                            
                            // Прогресс
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(progress), height: 12)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                        }
                    }
                    .frame(height: 12)
                }
            }
        }
        .padding(24)
        .boxingCard()
    }
}

/// Статистика калорий
struct CaloriesStatsCard: View {
    let total: Double
    let average: Double
    let workouts: Int
    let period: CaloriesTrackerView.TimePeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Статистика")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatBox(
                    title: "Всего",
                    value: "\(Int(total))",
                    subtitle: "ккал",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatBox(
                    title: "В среднем",
                    value: String(format: "%.0f", average),
                    subtitle: "ккал/день",
                    icon: "chart.bar.fill",
                    color: .red
                )
                
                StatBox(
                    title: "Тренировок",
                    value: "\(workouts)",
                    subtitle: period.rawValue,
                    icon: "dumbbell.fill",
                    color: .yellow
                )
                
                StatBox(
                    title: "Среднее",
                    value: workouts > 0 ? String(format: "%.0f", total / Double(workouts)) : "0",
                    subtitle: "ккал/тренировка",
                    icon: "timer",
                    color: .pink
                )
            }
        }
        .padding()
        .boxingCard()
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.cardBackgroundLight)
        .cornerRadius(12)
    }
}

/// График калорий
struct CaloriesChartCard: View {
    let workouts: [WorkoutSession]
    let period: CaloriesTrackerView.TimePeriod
    
    var chartData: [(date: String, calories: Double)] {
        let calendar = Calendar.current
        var data: [String: Double] = [:]
        
        for workout in workouts {
            let dayKey = calendar.startOfDay(for: workout.startDate)
            let formatter = DateFormatter()
            
            switch period {
            case .today:
                formatter.dateFormat = "HH:mm"
            case .week:
                formatter.dateFormat = "dd MMM"
            case .month:
                formatter.dateFormat = "dd MMM"
            }
            
            let dateString = formatter.string(from: dayKey)
            let calories = workout.caloriesBurned ?? 0
            data[dateString, default: 0] += calories
        }
        
        return data.map { (date: $0.key, calories: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("График калорий")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            if chartData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Нет данных за выбранный период")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(chartData.indices, id: \.self) { index in
                        let item = chartData[index]
                        VStack(spacing: 8) {
                            // Столбец
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.red],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 30, height: max(20, CGFloat(item.calories / 10)))
                            
                            // Значение
                            Text("\(Int(item.calories))")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            // Дата
                            Text(item.date)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .boxingCard()
    }
}

/// Топ тренировок по калориям
struct TopWorkoutsCard: View {
    let workouts: [WorkoutSession]
    
    var topWorkouts: [WorkoutSession] {
        workouts
            .filter { $0.caloriesBurned != nil }
            .sorted { ($0.caloriesBurned ?? 0) > ($1.caloriesBurned ?? 0) }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Топ тренировок")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            if topWorkouts.isEmpty {
                Text("Нет данных")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(topWorkouts.enumerated()), id: \.element.id) { index, workout in
                        HStack(spacing: 16) {
                            // Место
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: index < 3 ? [Color.orange, Color.red] : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 40)
                                
                                Text("\(index + 1)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatDate(workout.startDate))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                if let duration = workout.duration {
                                    Text(formatDuration(duration))
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            
                            Spacer()
                            
                            // Калории
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(Int(workout.caloriesBurned ?? 0))")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.orange)
                                
                                Text("ккал")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(12)
                        .background(Color.cardBackgroundLight)
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .boxingCard()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) мин"
    }
}

/// Детальная информация
struct DetailedCaloriesInfo: View {
    let workouts: [WorkoutSession]
    let period: CaloriesTrackerView.TimePeriod
    
    var totalCalories: Double {
        workouts.compactMap { $0.caloriesBurned }.reduce(0, +)
    }
    
    var maxCalories: Double {
        workouts.compactMap { $0.caloriesBurned }.max() ?? 0
    }
    
    var minCalories: Double {
        workouts.compactMap { $0.caloriesBurned }.min() ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Детальная информация")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                InfoRow(
                    title: "Всего сожжено",
                    value: "\(Int(totalCalories)) ккал",
                    icon: "flame.fill"
                )
                
                if maxCalories > 0 {
                    InfoRow(
                        title: "Максимум за тренировку",
                        value: "\(Int(maxCalories)) ккал",
                        icon: "arrow.up.circle.fill"
                    )
                }
                
                if minCalories > 0 {
                    InfoRow(
                        title: "Минимум за тренировку",
                        value: "\(Int(minCalories)) ккал",
                        icon: "arrow.down.circle.fill"
                    )
                }
                
                InfoRow(
                    title: "Количество тренировок",
                    value: "\(workouts.count)",
                    icon: "dumbbell.fill"
                )
            }
        }
        .padding()
        .boxingCard()
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.orange)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(12)
        .background(Color.cardBackgroundLight)
        .cornerRadius(10)
    }
}

#Preview {
    CaloriesTrackerView()
}

