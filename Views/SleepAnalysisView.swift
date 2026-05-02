//
//  SleepAnalysisView.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import SwiftUI
import Charts

/// Экран анализа сна и восстановления
struct SleepAnalysisView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var workoutManager = WorkoutManager.shared
    @State private var sleepData: [SleepData] = []
    @State private var recommendations: SleepRecommendation?
    @State private var selectedPeriod: TimePeriod = .week
    
    enum TimePeriod: String, CaseIterable {
        case week = "Неделя"
        case month = "Месяц"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Статистика сна
                        SleepStatisticsCard(sleepData: sleepData, selectedPeriod: $selectedPeriod)
                        
                        // Индекс качества сна
                        SleepQualityScoreCard(sleepData: sleepData, selectedPeriod: selectedPeriod)
                        
                        // График качества сна
                        SleepQualityChartCard(sleepData: sleepData, selectedPeriod: selectedPeriod)
                        
                        // Анализ фаз сна
                        SleepPhasesAnalysisCard(sleepData: sleepData, selectedPeriod: selectedPeriod)
                        
                        // Корреляция сна и тренировок
                        SleepWorkoutCorrelationCard(sleepData: sleepData, workoutManager: workoutManager)
                        
                        // Индекс восстановления
                        RecoveryIndexCard(sleepData: sleepData, workoutManager: workoutManager)
                        
                        // График активности за неделю
                        WeeklyActivityChart(workoutManager: workoutManager)
                        
                        // Показатели здоровья
                        HealthMetricsCard(
                            heartRate: healthKitManager.currentHeartRate,
                            sleepData: sleepData
                        )
                        
                        // Последний сон
                        if let lastSleep = sleepData.first {
                            LastSleepCard(sleep: lastSleep)
                        }
                        
                        // График фаз сна
                        if let lastSleep = sleepData.first {
                            SleepPhasesChart(sleep: lastSleep)
                        }
                        
                        // Тренды и сравнение
                        SleepTrendsCard(sleepData: sleepData, selectedPeriod: selectedPeriod)
                        
                        // Рекомендации
                        if let recommendations = recommendations {
                            SleepRecommendationsCard(recommendations: recommendations)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Сон и восстановление")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadSleepData()
                // Генерируем рекомендации с задержкой, чтобы данные успели загрузиться
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    generateRecommendations()
                }
            }
        }
    }
    
    private func loadSleepData() {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        healthKitManager.fetchSleepData(startDate: startDate, endDate: endDate) { data in
            if data.isEmpty {
                // Если нет реальных данных, генерируем демонстрационные
                DispatchQueue.main.async {
                    self.sleepData = self.generateDemoSleepData()
                }
            } else {
                DispatchQueue.main.async {
                    self.sleepData = data.sorted { $0.startDate > $1.startDate }
                }
            }
        }
    }
    
    /// Генерация демонстрационных данных о сне
    private func generateDemoSleepData() -> [SleepData] {
        let calendar = Calendar.current
        var sleepSessions: [SleepData] = []
        
        // Генерируем данные за последние 14 дней
        for day in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: -day, to: Date()) else { continue }
            
            // Время отхода ко сну: между 22:00 и 23:30
            let bedtimeHour = Int.random(in: 22...23)
            let bedtimeMinute = bedtimeHour == 22 ? Int.random(in: 0...59) : Int.random(in: 0...30)
            
            guard let sleepStart = calendar.date(bySettingHour: bedtimeHour, minute: bedtimeMinute, second: 0, of: date) else { continue }
            
            // Длительность сна: 6.5-9 часов
            let sleepDuration = Double.random(in: 6.5...9.0) * 3600
            guard let sleepEnd = calendar.date(byAdding: .second, value: Int(sleepDuration), to: sleepStart) else { continue }
            
            // Генерируем фазы сна
            var phases: [SleepPhase] = []
            var currentTime = sleepStart
            let totalPhases = Int.random(in: 8...12) // Количество циклов сна
            
            for i in 0..<totalPhases {
                let cycleDuration = sleepDuration / Double(totalPhases)
                let phaseStart = currentTime
                
                // Распределение фаз в цикле
                let phaseType: SleepPhaseType
                let phaseDuration: TimeInterval
                
                if i == 0 {
                    // Первый цикл: легкий сон
                    phaseType = .light
                    phaseDuration = cycleDuration * 0.3
                } else if i == totalPhases - 1 {
                    // Последний цикл: легкий сон или пробуждение
                    phaseType = Bool.random() ? .light : .awake
                    phaseDuration = cycleDuration * 0.2
                } else {
                    // Средние циклы: распределение фаз
                    let phaseRandom = Double.random(in: 0...1)
                    if phaseRandom < 0.15 {
                        phaseType = .deep
                        phaseDuration = cycleDuration * 0.4
                    } else if phaseRandom < 0.4 {
                        phaseType = .rem
                        phaseDuration = cycleDuration * 0.3
                    } else if phaseRandom < 0.05 {
                        phaseType = .awake
                        phaseDuration = cycleDuration * 0.1
                    } else {
                        phaseType = .light
                        phaseDuration = cycleDuration * 0.5
                    }
                }
                
                guard let phaseEnd = calendar.date(byAdding: .second, value: Int(phaseDuration), to: phaseStart),
                      phaseEnd <= sleepEnd else { break }
                
                phases.append(SleepPhase(
                    type: phaseType,
                    startDate: phaseStart,
                    endDate: phaseEnd
                ))
                
                currentTime = phaseEnd
                if currentTime >= sleepEnd { break }
            }
            
            // Средний пульс во время сна: 50-65 уд/мин
            let avgHeartRate = Double.random(in: 50...65)
            
            let sleepData = SleepData(
                startDate: sleepStart,
                endDate: sleepEnd,
                averageHeartRate: avgHeartRate,
                sleepPhases: phases
            )
            
            sleepSessions.append(sleepData)
        }
        
        return sleepSessions.sorted { $0.startDate > $1.startDate }
    }
    
    private func generateRecommendations() {
        guard let lastSleep = sleepData.first else {
            recommendations = SleepRecommendation(
                tips: [
                    "Установите регулярное время отхода ко сну - ложитесь спать в одно и то же время каждый день, даже в выходные",
                    "Избегайте экранов за 1-2 часа до сна - синий свет подавляет выработку мелатонина",
                    "Создайте комфортную обстановку для сна - прохладная температура (18-20°C), темнота, тишина",
                    "Избегайте кофеина после 14:00 - кофеин остается в организме до 8 часов",
                    "Регулярные физические нагрузки улучшают качество сна, но избегайте интенсивных тренировок за 3 часа до сна",
                    "Практикуйте техники релаксации перед сном - медитация, дыхательные упражнения, чтение",
                    "Не ешьте тяжелую пищу за 2-3 часа до сна - пищеварение мешает засыпанию",
                    "Ограничьте потребление алкоголя - хотя он помогает заснуть, он ухудшает качество глубокого сна"
                ]
            )
            return
        }
        
        var tips: [String] = []
        
        // Анализ продолжительности
        if lastSleep.durationInHours < 6 {
            tips.append("⚠️ Критически мало сна! Рекомендуется спать не менее 7-9 часов. Недостаток сна снижает производительность и замедляет восстановление после тренировок")
            tips.append("Попробуйте ложиться спать на 30-60 минут раньше. Даже небольшое увеличение продолжительности сна значительно улучшит восстановление")
            tips.append("Для спортсменов особенно важен сон - во время глубокого сна происходит восстановление мышц и выработка гормона роста")
        } else if lastSleep.durationInHours < 7 {
            tips.append("Продолжительность сна ниже оптимальной. Для спортсменов рекомендуется 8-10 часов сна для полного восстановления")
            tips.append("Увеличьте время сна на 30-60 минут - это улучшит восстановление и производительность на тренировках")
        } else if lastSleep.durationInHours >= 7 && lastSleep.durationInHours <= 9 {
            tips.append("✅ Продолжительность сна в норме. Продолжайте поддерживать этот режим")
        } else if lastSleep.durationInHours > 9 {
            tips.append("Продолжительность сна достаточна, но если вы чувствуете усталость, возможно, стоит проверить качество сна")
        }
        
        // Анализ фаз
        let deepSleepDuration = lastSleep.sleepPhases
            .filter { $0.type == .deep }
            .reduce(0.0) { $0 + $1.duration }
        
        let remSleepDuration = lastSleep.sleepPhases
            .filter { $0.type == .rem }
            .reduce(0.0) { $0 + $1.duration }
        
        let deepSleepPercentage = (deepSleepDuration / lastSleep.duration) * 100
        let remSleepPercentage = (remSleepDuration / lastSleep.duration) * 100
        
        if deepSleepPercentage < 15 {
            tips.append("⚠️ Недостаточно глубокого сна (менее 15%). Глубокий сон критически важен для восстановления мышц после тренировок")
            tips.append("Избегайте кофеина и алкоголя вечером - они нарушают глубокий сон")
            tips.append("Поддерживайте прохладную температуру в спальне (18-20°C) - это способствует глубокому сну")
            tips.append("Регулярные тренировки увеличивают время глубокого сна, но избегайте интенсивных нагрузок перед сном")
        } else if deepSleepPercentage >= 15 && deepSleepPercentage <= 25 {
            tips.append("✅ Время глубокого сна в норме. Глубокий сон важен для восстановления мышц и укрепления иммунитета")
        }
        
        if remSleepPercentage < 20 {
            tips.append("⚠️ Недостаточно REM-сна. REM-сон важен для когнитивного восстановления и обработки информации")
            tips.append("Недостаток REM-сна может ухудшить координацию и реакцию, что критично для бокса")
        }
        
        // Дополнительные советы по восстановлению
        tips.append("💡 Для оптимального восстановления после интенсивных тренировок: спите 8-10 часов, особенно в дни после тяжелых нагрузок")
        tips.append("📱 Используйте режим 'Не беспокоить' на телефоне во время сна - уведомления нарушают циклы сна")
        tips.append("🌙 Создайте ритуал перед сном: теплый душ, чтение, медитация - это сигнализирует мозгу о подготовке ко сну")
        tips.append("🏋️ После вечерних тренировок дайте телу 2-3 часа на остывание перед сном - это улучшит качество сна")
        tips.append("💧 Поддерживайте гидратацию в течение дня, но ограничьте потребление жидкости за 2 часа до сна")
        tips.append("🍎 Если голодны перед сном, выберите легкий перекус с триптофаном (банан, молоко) - это способствует засыпанию")
        tips.append("🧘 Практикуйте техники релаксации: прогрессивная мышечная релаксация, дыхание 4-7-8 (вдох 4 сек, задержка 7 сек, выдох 8 сек)")
        tips.append("📊 Отслеживайте связь между качеством сна и производительностью на тренировках - это поможет найти оптимальный режим")
        
        // Оптимальное время отхода ко сну
        let optimalBedtime = Calendar.current.date(byAdding: .hour, value: -8, to: Date())
        
        recommendations = SleepRecommendation(
            optimalBedtime: optimalBedtime,
            recommendedDuration: 8 * 3600,
            tips: tips
        )
    }
}

/// Карточка статистики сна
struct SleepStatisticsCard: View {
    let sleepData: [SleepData]
    @Binding var selectedPeriod: SleepAnalysisView.TimePeriod
    
    var filteredData: [SleepData] {
        let days = selectedPeriod == .week ? 7 : 30
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sleepData.filter { $0.startDate >= cutoff }
    }
    
    var averageDuration: Double {
        guard !filteredData.isEmpty else { return 0 }
        let total = filteredData.reduce(0.0) { $0 + $1.durationInHours }
        return total / Double(filteredData.count)
    }
    
    var totalSleepHours: Double {
        filteredData.reduce(0.0) { $0 + $1.durationInHours }
    }
    
    var averageDeepSleep: Double {
        guard !filteredData.isEmpty else { return 0 }
        let totalDeep = filteredData.reduce(0.0) { total, sleep in
            let deep = sleep.sleepPhases
                .filter { $0.type == .deep }
                .reduce(0.0) { $0 + $1.duration }
            return total + (deep / sleep.duration * 100)
        }
        return totalDeep / Double(filteredData.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Статистика сна")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Picker("Период", selection: $selectedPeriod) {
                    ForEach(SleepAnalysisView.TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 120)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatisticItem(
                    title: "Средняя продолжительность",
                    value: String(format: "%.1f ч", averageDuration),
                    icon: "moon.stars.fill",
                    color: .blue
                )
                
                StatisticItem(
                    title: "Всего часов сна",
                    value: String(format: "%.0f ч", totalSleepHours),
                    icon: "bed.double.fill",
                    color: .purple
                )
                
                StatisticItem(
                    title: "Глубокий сон",
                    value: String(format: "%.0f%%", averageDeepSleep),
                    icon: "waveform.path",
                    color: .indigo
                )
                
                StatisticItem(
                    title: "Записей",
                    value: "\(filteredData.count)",
                    icon: "calendar",
                    color: .orange
                )
            }
        }
        .padding()
        .boxingCard()
    }
}

struct StatisticItem: View {
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

/// График активности за неделю
struct WeeklyActivityChart: View {
    @ObservedObject var workoutManager: WorkoutManager
    
    var weekData: [(day: String, duration: Double)] {
        let calendar = Calendar.current
        var data: [(String, Double)] = []
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            
            let dayWorkouts = workoutManager.workoutHistory.filter { workout in
                calendar.isDate(workout.startDate, inSameDayAs: date)
            }
            
            let totalDuration = dayWorkouts.compactMap { $0.duration }.reduce(0.0, +) / 60.0 // в минутах
            data.append((dayName, totalDuration))
        }
        
        return data.reversed()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Активность за неделю")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weekData.indices, id: \.self) { index in
                    let item = weekData[index]
                    VStack(spacing: 8) {
                        // Столбец графика
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.yellow, Color.orange],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 30, height: max(20, CGFloat(item.duration) * 2))
                        
                        // Значение
                        Text("\(Int(item.duration))")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        // День недели
                        Text(item.day)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 180)
        }
        .padding()
        .boxingCard()
    }
}

/// Карточка показателей здоровья
struct HealthMetricsCard: View {
    let heartRate: Double?
    let sleepData: [SleepData]
    
    var restingHeartRate: Double? {
        // Берем средний ЧСС из последнего сна, если есть
        sleepData.first?.averageHeartRate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Показатели здоровья")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HealthMetricRow(
                    title: "Текущий пульс",
                    value: heartRate != nil ? "\(Int(heartRate!)) уд/мин" : "--",
                    icon: "heart.fill",
                    color: .red
                )
                
                HealthMetricRow(
                    title: "Пульс в покое",
                    value: restingHeartRate != nil ? "\(Int(restingHeartRate!)) уд/мин" : "--",
                    icon: "heart.circle.fill",
                    color: .green
                )
                
                HealthMetricRow(
                    title: "Качество сна",
                    value: calculateSleepQuality(),
                    icon: "moon.zzz.fill",
                    color: .blue
                )
            }
        }
        .padding()
        .boxingCard()
    }
    
    private func calculateSleepQuality() -> String {
        guard let lastSleep = sleepData.first else { return "Нет данных" }
        
        let deepSleep = lastSleep.sleepPhases
            .filter { $0.type == .deep }
            .reduce(0.0) { $0 + $1.duration }
        let deepPercentage = (deepSleep / lastSleep.duration) * 100
        
        if lastSleep.durationInHours >= 7 && deepPercentage >= 15 {
            return "Отличное"
        } else if lastSleep.durationInHours >= 6 && deepPercentage >= 10 {
            return "Хорошее"
        } else {
            return "Требует улучшения"
        }
    }
}

struct HealthMetricRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.cardBackgroundLight)
        .cornerRadius(12)
    }
}

/// Карточка последнего сна
struct LastSleepCard: View {
    let sleep: SleepData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Последний сон")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(String(format: "%.1f", sleep.durationInHours))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(formatDuration(sleep.duration))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Text(formatTime(sleep.startDate))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text("—")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text(formatTime(sleep.endDate))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            if let avgHR = sleep.averageHeartRate {
                HStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red.opacity(0.8))
                        .font(.system(size: 18))
                    Text("Средний пульс: \(Int(avgHR)) уд/мин")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.cardBackgroundLight.opacity(0.5))
                )
            }
        }
        .boxingCard()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)ч \(minutes)м"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Статистика за неделю
struct WeeklySleepStats: View {
    let sleepData: [SleepData]
    
    var averageDuration: Double {
        guard !sleepData.isEmpty else { return 0 }
        let total = sleepData.reduce(0.0) { $0 + $1.durationInHours }
        return total / Double(sleepData.count)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(averageDuration >= 7 ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .frame(width: 70, height: 70)
                
                Image(systemName: averageDuration >= 7 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(averageDuration >= 7 ? .green : .orange)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Средняя продолжительность")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("\(String(format: "%.1f", averageDuration)) ч")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("за последние 7 дней")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .boxingCard()
    }
}

/// График фаз сна
struct SleepPhasesChart: View {
    let sleep: SleepData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Фазы сна")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            Chart {
                ForEach(sleep.sleepPhases) { phase in
                    BarMark(
                        xStart: .value("Начало", phase.startDate),
                        xEnd: .value("Конец", phase.endDate),
                        y: .value("Фаза", phase.type.rawValue)
                    )
                    .foregroundStyle(Color(phase.type.color))
                }
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            
            // Легенда
            HStack(spacing: 20) {
                ForEach([SleepPhaseType.deep, .rem, .light, .awake], id: \.self) { type in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(type.color))
                            .frame(width: 10, height: 10)
                        Text(type.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .boxingCard()
    }
}

/// Карточка рекомендаций
struct SleepRecommendationsCard: View {
    let recommendations: SleepRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Рекомендации")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            if let bedtime = recommendations.optimalBedtime {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Оптимальное время")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(formatTime(bedtime))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(12)
                .background(Color.cardBackgroundLight)
                .cornerRadius(12)
            }
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(recommendations.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.gradientWarning)
                                .padding(.top, 2)
                            
                            Text(tip)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .background(Color.cardBackgroundLight.opacity(0.5))
                        .cornerRadius(10)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .boxingCard()
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Карточка индекса качества сна
struct SleepQualityScoreCard: View {
    let sleepData: [SleepData]
    let selectedPeriod: SleepAnalysisView.TimePeriod
    
    var filteredData: [SleepData] {
        let days = selectedPeriod == .week ? 7 : 30
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sleepData.filter { $0.startDate >= cutoff }
    }
    
    var qualityScore: Double {
        guard !filteredData.isEmpty else { return 75.0 } // Демо-значение
        
        var totalScore = 0.0
        for sleep in filteredData {
            var score = 0.0
            
            // Оценка по продолжительности (40%)
            let durationScore = min(100, (sleep.durationInHours / 8.0) * 100)
            score += durationScore * 0.4
            
            // Оценка по глубокому сну (30%)
            let deepSleep = sleep.sleepPhases.filter { $0.type == .deep }.reduce(0.0) { $0 + $1.duration }
            let deepPercentage = (deepSleep / sleep.duration) * 100
            let deepScore = min(100, (deepPercentage / 20.0) * 100) // 20% - идеальный глубокий сон
            score += deepScore * 0.3
            
            // Оценка по REM-сну (20%)
            let remSleep = sleep.sleepPhases.filter { $0.type == .rem }.reduce(0.0) { $0 + $1.duration }
            let remPercentage = (remSleep / sleep.duration) * 100
            let remScore = min(100, (remPercentage / 25.0) * 100) // 25% - идеальный REM
            score += remScore * 0.2
            
            // Оценка по бодрствованию (10%) - меньше лучше
            let awakeSleep = sleep.sleepPhases.filter { $0.type == .awake }.reduce(0.0) { $0 + $1.duration }
            let awakePercentage = (awakeSleep / sleep.duration) * 100
            let awakeScore = max(0, 100 - (awakePercentage * 2)) // Штраф за бодрствование
            score += awakeScore * 0.1
            
            totalScore += score
        }
        
        return totalScore / Double(filteredData.count)
    }
    
    var qualityLevel: (text: String, color: Color) {
        if qualityScore >= 85 { return ("Отличное", .green) }
        if qualityScore >= 70 { return ("Хорошее", .yellow) }
        if qualityScore >= 55 { return ("Среднее", .orange) }
        return ("Требует улучшения", .red)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Индекс качества сна")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                    .foregroundColor(qualityLevel.color)
            }
            
            HStack(spacing: 30) {
                // Круговой индикатор
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 12)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(qualityScore / 100))
                        .stroke(
                            AngularGradient(
                                colors: [qualityLevel.color, qualityLevel.color.opacity(0.6)],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: qualityScore)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(qualityScore))")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("/100")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(qualityLevel.color)
                            .frame(width: 12, height: 12)
                        
                        Text(qualityLevel.text)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("На основе продолжительности, фаз сна и стабильности")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .boxingCard()
    }
}

/// График качества сна
struct SleepQualityChartCard: View {
    let sleepData: [SleepData]
    let selectedPeriod: SleepAnalysisView.TimePeriod
    
    var filteredData: [SleepData] {
        let days = selectedPeriod == .week ? 7 : 30
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sleepData.filter { $0.startDate >= cutoff }
    }
    
    var chartData: [(date: String, score: Double)] {
        let calendar = Calendar.current
        var data: [(String, Double)] = []
        
        for sleep in filteredData {
            let formatter = DateFormatter()
            formatter.dateFormat = selectedPeriod == .week ? "dd MMM" : "dd MMM"
            let dateString = formatter.string(from: sleep.startDate)
            
            // Рассчитываем качество для каждого сна
            var score = 0.0
            let durationScore = min(100, (sleep.durationInHours / 8.0) * 100)
            score += durationScore * 0.4
            
            let deepSleep = sleep.sleepPhases.filter { $0.type == .deep }.reduce(0.0) { $0 + $1.duration }
            let deepPercentage = (deepSleep / sleep.duration) * 100
            let deepScore = min(100, (deepPercentage / 20.0) * 100)
            score += deepScore * 0.3
            
            let remSleep = sleep.sleepPhases.filter { $0.type == .rem }.reduce(0.0) { $0 + $1.duration }
            let remPercentage = (remSleep / sleep.duration) * 100
            let remScore = min(100, (remPercentage / 25.0) * 100)
            score += remScore * 0.2
            
            let awakeSleep = sleep.sleepPhases.filter { $0.type == .awake }.reduce(0.0) { $0 + $1.duration }
            let awakePercentage = (awakeSleep / sleep.duration) * 100
            let awakeScore = max(0, 100 - (awakePercentage * 2))
            score += awakeScore * 0.1
            
            data.append((dateString, score))
        }
        
        return data.sorted { (item1: (date: String, score: Double), item2: (date: String, score: Double)) -> Bool in
            item1.date < item2.date
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("График качества сна")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            if chartData.isEmpty {
                Text("Нет данных за выбранный период")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(chartData.indices, id: \.self) { index in
                        let item = chartData[index]
                        let color: Color = item.score >= 85 ? .green : (item.score >= 70 ? .yellow : (item.score >= 55 ? .orange : .red))
                        
                        VStack(spacing: 8) {
                            // Столбец
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .frame(width: 25, height: max(15, CGFloat(item.score) * 1.5))
                            
                            // Значение
                            Text("\(Int(item.score))")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            // Дата
                            Text(item.date)
                                .font(.system(size: 8, weight: .medium))
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

/// Анализ фаз сна
struct SleepPhasesAnalysisCard: View {
    let sleepData: [SleepData]
    let selectedPeriod: SleepAnalysisView.TimePeriod
    
    var filteredData: [SleepData] {
        let days = selectedPeriod == .week ? 7 : 30
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sleepData.filter { $0.startDate >= cutoff }
    }
    
    var phasesStats: [(type: SleepPhaseType, percentage: Double, duration: Double)] {
        guard !filteredData.isEmpty else { return [] }
        
        var totalDeep = 0.0
        var totalREM = 0.0
        var totalLight = 0.0
        var totalAwake = 0.0
        var totalDuration = 0.0
        
        for sleep in filteredData {
            totalDuration += sleep.duration
            
            for phase in sleep.sleepPhases {
                switch phase.type {
                case .deep: totalDeep += phase.duration
                case .rem: totalREM += phase.duration
                case .light: totalLight += phase.duration
                case .awake: totalAwake += phase.duration
                }
            }
        }
        
        return [
            (.deep, (totalDeep / totalDuration) * 100, totalDeep / 3600),
            (.rem, (totalREM / totalDuration) * 100, totalREM / 3600),
            (.light, (totalLight / totalDuration) * 100, totalLight / 3600),
            (.awake, (totalAwake / totalDuration) * 100, totalAwake / 3600)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Анализ фаз сна")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            if phasesStats.isEmpty {
                Text("Нет данных")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(phasesStats, id: \.type) { stat in
                        HStack(spacing: 16) {
                            // Цветной индикатор
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(stat.type.color))
                                .frame(width: 6, height: 50)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(stat.type.rawValue)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Text(String(format: "%.1f ч", stat.duration))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("•")
                                        .foregroundColor(.white.opacity(0.4))
                                    
                                    Text(String(format: "%.0f%%", stat.percentage))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            
                            Spacer()
                            
                            // Прогресс-бар
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(stat.type.color))
                                        .frame(width: geometry.size.width * CGFloat(stat.percentage / 100), height: 6)
                                }
                            }
                            .frame(width: 80, height: 6)
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
}

/// Корреляция сна и тренировок
struct SleepWorkoutCorrelationCard: View {
    let sleepData: [SleepData]
    @ObservedObject var workoutManager: WorkoutManager
    
    var correlation: (sleepHours: Double, workoutDuration: Double, correlation: String) {
        let calendar = Calendar.current
        var sleepHours: [Double] = []
        var workoutDurations: [Double] = []
        
        // Собираем данные за последние 7 дней
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            // Сон за день
            let daySleep = sleepData.filter { $0.startDate >= dayStart && $0.startDate < dayEnd }
            let totalSleep = daySleep.reduce(0.0) { $0 + $1.durationInHours }
            sleepHours.append(totalSleep)
            
            // Тренировки за день
            let dayWorkouts = workoutManager.workoutHistory.filter { workout in
                calendar.isDate(workout.startDate, inSameDayAs: date)
            }
            let totalWorkout = dayWorkouts.compactMap { $0.duration }.reduce(0.0, +) / 3600.0
            workoutDurations.append(totalWorkout)
        }
        
        let avgSleep = sleepHours.reduce(0, +) / Double(sleepHours.count)
        let avgWorkout = workoutDurations.reduce(0, +) / Double(workoutDurations.count)
        
        var correlationText = "Положительная"
        if avgSleep < 7 && avgWorkout > 1 {
            correlationText = "⚠️ Недостаток сна при высокой активности"
        } else if avgSleep >= 8 && avgWorkout > 0.5 {
            correlationText = "✅ Оптимальный баланс"
        }
        
        return (avgSleep, avgWorkout, correlationText)
    }
    
    var body: some View {
        let corr = correlation
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Сон и тренировки")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundColor(.blue)
                        Text("Средний сон")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text(String(format: "%.1f ч", corr.sleepHours))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    HStack {
                        Text("Средняя тренировка")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Image(systemName: "dumbbell.fill")
                            .foregroundColor(.orange)
                    }
                    
                    Text(String(format: "%.1f ч", corr.workoutDuration))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack {
                Image(systemName: corr.correlation.contains("✅") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(corr.correlation.contains("✅") ? .green : .orange)
                
                Text(corr.correlation)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(Color.cardBackgroundLight)
            .cornerRadius(10)
        }
        .padding()
        .boxingCard()
    }
}

/// Индекс восстановления
struct RecoveryIndexCard: View {
    let sleepData: [SleepData]
    @ObservedObject var workoutManager: WorkoutManager
    
    var recoveryIndex: Double {
        guard let lastSleep = sleepData.first else { return 65.0 } // Демо-значение
        
        var index = 0.0
        
        // Фактор сна (50%)
        let sleepScore = min(100, (lastSleep.durationInHours / 8.0) * 100)
        index += sleepScore * 0.5
        
        // Фактор глубокого сна (30%)
        let deepSleep = lastSleep.sleepPhases.filter { $0.type == .deep }.reduce(0.0) { $0 + $1.duration }
        let deepPercentage = (deepSleep / lastSleep.duration) * 100
        let deepScore = min(100, (deepPercentage / 20.0) * 100)
        index += deepScore * 0.3
        
        // Фактор времени после последней тренировки (20%)
        if let lastWorkout = workoutManager.workoutHistory.first {
            let hoursSinceWorkout = Date().timeIntervalSince(lastWorkout.startDate) / 3600
            let recoveryScore = min(100, (hoursSinceWorkout / 24.0) * 100) // 24 часа = 100%
            index += recoveryScore * 0.2
        } else {
            index += 100 * 0.2 // Нет тренировок = полное восстановление
        }
        
        return min(100, index)
    }
    
    var recoveryStatus: (text: String, color: Color, icon: String) {
        let index = recoveryIndex
        if index >= 80 {
            return ("Отличное восстановление", .green, "checkmark.circle.fill")
        } else if index >= 60 {
            return ("Хорошее восстановление", .yellow, "checkmark.circle")
        } else if index >= 40 {
            return ("Частичное восстановление", .orange, "exclamationmark.circle")
        } else {
            return ("Требуется отдых", .red, "xmark.circle.fill")
        }
    }
    
    var body: some View {
        let status = recoveryStatus
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Индекс восстановления")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 24) {
                // Круговой индикатор
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(recoveryIndex / 100))
                        .stroke(
                            AngularGradient(
                                colors: [status.color, status.color.opacity(0.6)],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: recoveryIndex)
                    
                    Text("\(Int(recoveryIndex))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: status.icon)
                            .foregroundColor(status.color)
                            .font(.system(size: 20))
                        
                        Text(status.text)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("На основе качества сна и времени после тренировки")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .boxingCard()
    }
}

/// Тренды и сравнение
struct SleepTrendsCard: View {
    let sleepData: [SleepData]
    let selectedPeriod: SleepAnalysisView.TimePeriod
    
    var filteredData: [SleepData] {
        let days = selectedPeriod == .week ? 7 : 30
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sleepData.filter { $0.startDate >= cutoff }
    }
    
    var currentPeriodAvg: Double {
        guard !filteredData.isEmpty else { return 7.5 }
        return filteredData.reduce(0.0) { $0 + $1.durationInHours } / Double(filteredData.count)
    }
    
    var previousPeriodAvg: Double {
        let days = selectedPeriod == .week ? 7 : 30
        let currentCutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let previousCutoff = Calendar.current.date(byAdding: .day, value: -days * 2, to: Date()) ?? Date()
        
        let previousData = sleepData.filter { $0.startDate >= previousCutoff && $0.startDate < currentCutoff }
        guard !previousData.isEmpty else { return currentPeriodAvg }
        return previousData.reduce(0.0) { $0 + $1.durationInHours } / Double(previousData.count)
    }
    
    var trend: (direction: String, change: Double, color: Color) {
        let change = currentPeriodAvg - previousPeriodAvg
        if abs(change) < 0.1 {
            return ("Стабильно", 0, .gray)
        } else if change > 0 {
            return ("Улучшение", change, .green)
        } else {
            return ("Ухудшение", abs(change), .red)
        }
    }
    
    var body: some View {
        let trendData = trend
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Тренды")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Текущий период")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(String(format: "%.1f ч", currentPeriodAvg))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: trendData.direction == "Улучшение" ? "arrow.up.right" : (trendData.direction == "Ухудшение" ? "arrow.down.right" : "arrow.right"))
                        .font(.system(size: 24))
                        .foregroundColor(trendData.color)
                    
                    if trendData.change > 0 {
                        Text(String(format: "+%.1f ч", trendData.change))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(trendData.color)
                    } else if trendData.change < 0 {
                        Text(String(format: "-%.1f ч", trendData.change))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(trendData.color)
                    } else {
                        Text("Без изменений")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Предыдущий период")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(String(format: "%.1f ч", previousPeriodAvg))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Text(trendData.direction)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(trendData.color)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(12)
                .background(trendData.color.opacity(0.2))
                .cornerRadius(10)
        }
        .padding()
        .boxingCard()
    }
}

#Preview {
    SleepAnalysisView()
}
