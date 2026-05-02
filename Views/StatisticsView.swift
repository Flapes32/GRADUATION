//
//  StatisticsView.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import SwiftUI
import Charts

/// Подробный экран статистики
struct StatisticsView: View {
    @StateObject private var workoutManager = WorkoutManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var selectedPeriod: TimePeriod = .week
    
    enum TimePeriod: String, CaseIterable {
        case week = "Неделя"
        case month = "Месяц"
        case all = "Все время"
    }
    
    var filteredWorkouts: [WorkoutSession] {
        let calendar = Calendar.current
        let now = Date()
        let cutoff: Date
        
        switch selectedPeriod {
        case .week:
            cutoff = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            cutoff = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .all:
            return workoutManager.workoutHistory
        }
        
        return workoutManager.workoutHistory.filter { $0.startDate >= cutoff }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Переключатель периода
                        StatisticsPeriodSelector(selectedPeriod: $selectedPeriod)
                        
                        // Общая статистика
                        OverallStatsCard(workouts: filteredWorkouts)
                        
                        // Статистика по ЧСС
                        StatisticsHeartRateStatsCard(workouts: filteredWorkouts)
                        
                        // График тренировок по дням
                        WorkoutsChartCard(workouts: filteredWorkouts, period: selectedPeriod)
                        
                        // Статистика по времени
                        TimeStatsCard(workouts: filteredWorkouts)
                        
                        // Статистика по нагрузкам
                        LoadStatsCard(workouts: filteredWorkouts)
                        
                        // Статистика по восстановлению
                        RecoveryStatsCard(workouts: filteredWorkouts)
                        
                        // Детальная информация
                        DetailedInfoCard(workouts: filteredWorkouts)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Статистика")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

/// Переключатель периода
struct StatisticsPeriodSelector: View {
    @Binding var selectedPeriod: StatisticsView.TimePeriod
    
    var body: some View {
        Picker("Период", selection: $selectedPeriod) {
            ForEach(StatisticsView.TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
}

/// Карточка общей статистики
struct OverallStatsCard: View {
    let workouts: [WorkoutSession]
    
    var totalWorkouts: Int { workouts.count }
    
    var totalDuration: TimeInterval {
        workouts.compactMap { $0.duration }.reduce(0, +)
    }
    
    var totalCalories: Double {
        // Используем реальные калории из тренировок, если есть
        let caloriesFromWorkouts = workouts.compactMap { $0.caloriesBurned }.reduce(0, +)
        if caloriesFromWorkouts > 0 {
            return caloriesFromWorkouts
        }
        // Если нет, рассчитываем примерно: 10-12 ккал/мин для интенсивной тренировки
        let totalMinutes = totalDuration / 60
        return totalMinutes * 11 // Среднее значение
    }
    
    var avgDuration: Double {
        guard !workouts.isEmpty else { return 0 }
        return totalDuration / Double(workouts.count) / 60 // в минутах
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Общая статистика")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatisticBox(
                    title: "Тренировок",
                    value: "\(totalWorkouts)",
                    icon: "dumbbell.fill",
                    color: .blue
                )
                
                StatisticBox(
                    title: "Всего времени",
                    value: formatDuration(totalDuration),
                    icon: "clock.fill",
                    color: .green
                )
                
                StatisticBox(
                    title: "Средняя длительность",
                    value: String(format: "%.0f мин", avgDuration),
                    icon: "timer",
                    color: .orange
                )
                
                StatisticBox(
                    title: "Сожжено калорий",
                    value: String(format: "%.0f ккал", totalCalories),
                    icon: "flame.fill",
                    color: .red
                )
            }
        }
        .padding()
        .boxingCard()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)ч \(minutes)м"
        }
        return "\(minutes) мин"
    }
}

/// Карточка статистики по ЧСС для экрана статистики
struct StatisticsHeartRateStatsCard: View {
    let workouts: [WorkoutSession]
    
    var allHeartRates: [Double] {
        workouts.flatMap { $0.heartRateData.map { $0.value } }
    }
    
    var avgHeartRate: Double {
        guard !allHeartRates.isEmpty else { return 0 }
        return allHeartRates.reduce(0, +) / Double(allHeartRates.count)
    }
    
    var maxHeartRate: Double {
        allHeartRates.max() ?? 0
    }
    
    var minHeartRate: Double {
        allHeartRates.min() ?? 0
    }
    
    var avgWorkoutHeartRate: Double {
        let workoutAvgs = workouts.compactMap { workout -> Double? in
            guard !workout.heartRateData.isEmpty else { return nil }
            return workout.heartRateData.map { $0.value }.reduce(0, +) / Double(workout.heartRateData.count)
        }
        guard !workoutAvgs.isEmpty else { return 0 }
        return workoutAvgs.reduce(0, +) / Double(workoutAvgs.count)
    }
    
    var timeInZones: (aerobic: Double, anaerobic: Double, max: Double) {
        var aerobic = 0.0
        var anaerobic = 0.0
        var max = 0.0
        
        for workout in workouts {
            for hrData in workout.heartRateData {
                let hr = hrData.value
                if hr >= 190 {
                    max += 5 // 5 секунд на точку данных
                } else if hr >= 160 {
                    anaerobic += 5
                } else if hr >= 120 {
                    aerobic += 5
                }
            }
        }
        
        return (aerobic, anaerobic, max)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Статистика по ЧСС")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    HeartRateMetric(
                        title: "Средний ЧСС",
                        value: String(format: "%.0f", avgHeartRate),
                        subtitle: "по всем данным"
                    )
                    
                    HeartRateMetric(
                        title: "Макс. ЧСС",
                        value: String(format: "%.0f", maxHeartRate),
                        subtitle: "пиковое значение"
                    )
                }
                
                HStack(spacing: 20) {
                    HeartRateMetric(
                        title: "Мин. ЧСС",
                        value: String(format: "%.0f", minHeartRate),
                        subtitle: "в покое"
                    )
                    
                    HeartRateMetric(
                        title: "Средний на тренировке",
                        value: String(format: "%.0f", avgWorkoutHeartRate),
                        subtitle: "среднее по тренировкам"
                    )
                }
            }
            
            // Время в зонах
            VStack(alignment: .leading, spacing: 10) {
                Text("Время в зонах ЧСС")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                let zones = timeInZones
                let total = zones.aerobic + zones.anaerobic + zones.max
                
                if total > 0 {
                    ZoneBar(
                        title: "Аэробная (120-160)",
                        time: zones.aerobic,
                        total: total,
                        color: .green
                    )
                    
                    ZoneBar(
                        title: "Анаэробная (160-190)",
                        time: zones.anaerobic,
                        total: total,
                        color: .orange
                    )
                    
                    ZoneBar(
                        title: "Максимальная (190+)",
                        time: zones.max,
                        total: total,
                        color: .red
                    )
                }
            }
        }
        .padding()
        .boxingCard()
    }
}

struct HeartRateMetric: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.cardBackgroundLight)
        .cornerRadius(12)
    }
}

struct ZoneBar: View {
    let title: String
    let time: Double
    let total: Double
    let color: Color
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return (time / total) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(String(format: "%.0f%%", percentage))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

/// График тренировок по дням
struct WorkoutsChartCard: View {
    let workouts: [WorkoutSession]
    let period: StatisticsView.TimePeriod
    
    var chartData: [(day: String, count: Int, duration: Double)] {
        let calendar = Calendar.current
        var data: [String: (count: Int, duration: Double)] = [:]
        
        for workout in workouts {
            let dayKey = calendar.startOfDay(for: workout.startDate)
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM"
            let dayString = formatter.string(from: dayKey)
            
            let existing = data[dayString] ?? (0, 0.0)
            data[dayString] = (
                existing.count + 1,
                existing.duration + (workout.duration ?? 0)
            )
        }
        
        return data.map { (day: $0.key, count: $0.value.count, duration: $0.value.duration) }
            .sorted { $0.day < $1.day }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("График тренировок")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            if chartData.isEmpty {
                Text("Нет данных за выбранный период")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(chartData.indices, id: \.self) { index in
                        let item = chartData[index]
                        VStack(spacing: 8) {
                            // Столбец
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.yellow, Color.orange],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 30, height: max(20, CGFloat(item.count) * 15))
                            
                            // Значение
                            Text("\(item.count)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            // День
                            Text(item.day)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 180)
            }
        }
        .padding()
        .boxingCard()
    }
}

/// Статистика по времени
struct TimeStatsCard: View {
    let workouts: [WorkoutSession]
    
    var totalTime: TimeInterval {
        workouts.compactMap { $0.duration }.reduce(0, +)
    }
    
    var avgTime: Double {
        guard !workouts.isEmpty else { return 0 }
        return totalTime / Double(workouts.count) / 60
    }
    
    var longestWorkout: TimeInterval {
        workouts.compactMap { $0.duration }.max() ?? 0
    }
    
    var shortestWorkout: TimeInterval {
        workouts.compactMap { $0.duration }.min() ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Статистика по времени")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                DetailRow(
                    title: "Общее время тренировок",
                    value: formatTime(totalTime),
                    icon: "clock.fill"
                )
                
                DetailRow(
                    title: "Средняя длительность",
                    value: String(format: "%.0f минут", avgTime),
                    icon: "timer"
                )
                
                DetailRow(
                    title: "Самая длинная тренировка",
                    value: formatTime(longestWorkout),
                    icon: "arrow.up.circle.fill"
                )
                
                DetailRow(
                    title: "Самая короткая тренировка",
                    value: formatTime(shortestWorkout),
                    icon: "arrow.down.circle.fill"
                )
            }
        }
        .padding()
        .boxingCard()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        if hours > 0 {
            return "\(hours)ч \(minutes)м"
        }
        return "\(minutes) мин"
    }
}

/// Статистика по нагрузкам
struct LoadStatsCard: View {
    let workouts: [WorkoutSession]
    
    var totalPeakLoads: Int {
        workouts.reduce(0) { $0 + $1.peakLoads.count }
    }
    
    var avgPeakLoads: Double {
        guard !workouts.isEmpty else { return 0 }
        return Double(totalPeakLoads) / Double(workouts.count)
    }
    
    var maxPeakLoads: Int {
        workouts.map { $0.peakLoads.count }.max() ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Пиковые нагрузки")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                DetailRow(
                    title: "Всего пиковых нагрузок",
                    value: "\(totalPeakLoads)",
                    icon: "flame.fill"
                )
                
                DetailRow(
                    title: "Среднее на тренировку",
                    value: String(format: "%.1f", avgPeakLoads),
                    icon: "chart.bar.fill"
                )
                
                DetailRow(
                    title: "Максимум за тренировку",
                    value: "\(maxPeakLoads)",
                    icon: "arrow.up.circle.fill"
                )
            }
        }
        .padding()
        .boxingCard()
    }
}

/// Статистика по восстановлению
struct RecoveryStatsCard: View {
    let workouts: [WorkoutSession]
    
    var avgRecoveryTime: Double {
        let recoveries = workouts.compactMap { $0.recoveryTime }
        guard !recoveries.isEmpty else { return 0 }
        return recoveries.reduce(0, +) / Double(recoveries.count) / 60
    }
    
    var minRecoveryTime: Double {
        workouts.compactMap { $0.recoveryTime }.min() ?? 0 / 60
    }
    
    var maxRecoveryTime: Double {
        workouts.compactMap { $0.recoveryTime }.max() ?? 0 / 60
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Восстановление")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                DetailRow(
                    title: "Среднее время восстановления",
                    value: String(format: "%.1f минут", avgRecoveryTime),
                    icon: "arrow.down.circle.fill"
                )
                
                if minRecoveryTime > 0 {
                    DetailRow(
                        title: "Минимальное время",
                        value: String(format: "%.1f минут", minRecoveryTime),
                        icon: "arrow.down.circle"
                    )
                }
                
                if maxRecoveryTime > 0 {
                    DetailRow(
                        title: "Максимальное время",
                        value: String(format: "%.1f минут", maxRecoveryTime),
                        icon: "arrow.up.circle"
                    )
                }
            }
        }
        .padding()
        .boxingCard()
    }
}

/// Детальная информация
struct DetailedInfoCard: View {
    let workouts: [WorkoutSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Детальная информация")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                DetailRow(
                    title: "Всего записей ЧСС",
                    value: "\(workouts.reduce(0) { $0 + $1.heartRateData.count })",
                    icon: "heart.fill"
                )
                
                DetailRow(
                    title: "Всего записей лактата",
                    value: "\(workouts.reduce(0) { $0 + $1.lactateData.count })",
                    icon: "waveform.path"
                )
                
                DetailRow(
                    title: "Период тренировок",
                    value: formatPeriod(),
                    icon: "calendar"
                )
            }
        }
        .padding()
        .boxingCard()
    }
    
    private func formatPeriod() -> String {
        guard let first = workouts.first?.startDate,
              let last = workouts.last?.startDate else {
            return "Нет данных"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return "\(formatter.string(from: last)) - \(formatter.string(from: first))"
    }
}

struct StatisticBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.cardBackgroundLight)
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.yellow)
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
    StatisticsView()
}

