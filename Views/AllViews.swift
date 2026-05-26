import SwiftUI
import Charts

// MARK: - Heart Rate Monitor View

struct HeartRateMonitorView: View {
    @EnvironmentObject var healthKit: HealthKitManager
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var history: [HeartRateRecord] = []
    @State private var restingHR: Double = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current HR
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.red.opacity(0.15))
                        VStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 40)).foregroundColor(.red)
                            Text("\(Int(healthKit.currentHeartRate))")
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("уд/мин — текущий").foregroundColor(.gray)
                            HStack(spacing: 24) {
                                VStack {
                                    Text("\(Int(restingHR))").font(.title2).bold().foregroundColor(.white)
                                    Text("покой").font(.caption).foregroundColor(.gray)
                                }
                                VStack {
                                    Text("\(Int(history.map(\.value).max() ?? 0))").font(.title2).bold().foregroundColor(.orange)
                                    Text("макс. сегодня").font(.caption).foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal)

                    // Chart
                    if !history.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ЧСС за последние 24 часа")
                                .font(.headline).foregroundColor(.white)
                            Chart(history.suffix(100)) { record in
                                LineMark(
                                    x: .value("Время", record.timestamp),
                                    y: .value("ЧСС", record.value)
                                )
                                .foregroundStyle(Color.red)
                                .interpolationMethod(.catmullRom)
                            }
                            .frame(height: 160)
                            .chartYScale(domain: 40...220)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    // HR Zones
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Зоны ЧСС").font(.headline).foregroundColor(.white)
                        ForEach(hrZones, id: \.name) { zone in
                            HRZoneRow(zone: zone, currentHR: healthKit.currentHeartRate, maxHR: Double(workoutManager.maxHeartRate))
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("ЧСС")
        }
        .task {
            history = await healthKit.fetchHeartRateHistory(days: 1)
            restingHR = await healthKit.fetchRestingHeartRate()
            healthKit.startHeartRateStreaming()
        }
    }

    let hrZones: [HRZone] = [
        HRZone(name: "Восстановление", range: 0.50...0.60, color: .blue),
        HRZone(name: "Аэробная",       range: 0.60...0.70, color: .green),
        HRZone(name: "Пороговая",      range: 0.70...0.85, color: .yellow),
        HRZone(name: "Анаэробная",     range: 0.85...0.95, color: .orange),
        HRZone(name: "Максимальная",   range: 0.95...1.00, color: .red),
    ]
}

struct HRZone { let name: String; let range: ClosedRange<Double>; let color: Color }

struct HRZoneRow: View {
    let zone: HRZone; let currentHR: Double; let maxHR: Double
    var hrPercent: Double { currentHR / maxHR }
    var isActive: Bool { zone.range.contains(hrPercent) }
    var body: some View {
        HStack {
            Circle().fill(zone.color).frame(width: 10, height: 10)
            Text(zone.name).foregroundColor(isActive ? .white : .gray).font(.subheadline)
            Spacer()
            Text("\(Int(zone.range.lowerBound * maxHR))–\(Int(zone.range.upperBound * maxHR)) уд/мин")
                .font(.caption).foregroundColor(.gray)
            if isActive {
                Text("Активна").font(.caption).bold().foregroundColor(zone.color)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(zone.color.opacity(0.2)).cornerRadius(6)
            }
        }
    }
}

// MARK: - Statistics View

struct StatisticsView: View {
    @State private var workouts: [WorkoutSession] = []
    @State private var selectedPeriod: Int = 7
    private let repo = WorkoutRepository()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Период", selection: $selectedPeriod) {
                        Text("7 дней").tag(7)
                        Text("30 дней").tag(30)
                        Text("90 дней").tag(90)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Summary cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Тренировок",
                                 value: "\(workouts.count)", unit: "за период",
                                 icon: "dumbbell.fill", color: .blue)
                        StatCard(title: "Калорий",
                                 value: "\(Int(workouts.map(\.totalCalories).reduce(0,+)))", unit: "ккал",
                                 icon: "flame.fill", color: .orange)
                        StatCard(title: "Средний ЧСС",
                                 value: workouts.isEmpty ? "–" : "\(Int(workouts.map(\.averageHeartRate).reduce(0,+)/Double(workouts.count)))",
                                 unit: "уд/мин", icon: "heart.fill", color: .red)
                        StatCard(title: "Раундов",
                                 value: "\(workouts.flatMap(\.rounds).count)", unit: "всего",
                                 icon: "bolt.fill", color: .yellow)
                    }
                    .padding(.horizontal)

                    // Workouts list
                    if !workouts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("История").font(.headline).foregroundColor(.white)
                            ForEach(workouts) { workout in
                                WorkoutDetailRow(workout: workout)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar").font(.system(size: 48)).foregroundColor(.gray)
                            Text("Нет тренировок за период").foregroundColor(.gray)
                        }
                        .padding(.top, 60)
                    }
                }
                .padding(.top)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Статистика")
            .onChange(of: selectedPeriod) { _ in loadWorkouts() }
        }
        .onAppear { loadWorkouts() }
    }

    private func loadWorkouts() {
        let from = Calendar.current.date(byAdding: .day, value: -selectedPeriod, to: Date()) ?? Date()
        workouts = repo.fetchWorkouts(from: from, to: Date())
    }
}

struct WorkoutDetailRow: View {
    let workout: WorkoutSession
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.phase.rawValue).font(.subheadline).bold().foregroundColor(.white)
                Spacer()
                Text(workout.startDate, style: .date).font(.caption).foregroundColor(.gray)
            }
            HStack(spacing: 16) {
                Label("\(Int(workout.averageHeartRate)) уд/мин", systemImage: "heart.fill")
                    .font(.caption).foregroundColor(.red)
                Label("\(Int(workout.totalCalories)) ккал", systemImage: "flame.fill")
                    .font(.caption).foregroundColor(.orange)
                Label("\(workout.rounds.count) раундов", systemImage: "bolt.fill")
                    .font(.caption).foregroundColor(.yellow)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Sleep Analysis View

struct SleepAnalysisView: View {
    @EnvironmentObject var healthKit: HealthKitManager
    @State private var sleepData: [SleepData] = []
    @State private var selectedPeriod: Int = 7
    private let repo = WorkoutRepository()

    var avgDuration: Double {
        guard !sleepData.isEmpty else { return 0 }
        return sleepData.map(\.durationInHours).reduce(0,+) / Double(sleepData.count)
    }

    var avgQuality: Double {
        guard !sleepData.isEmpty else { return 0 }
        return sleepData.map(\.qualityScore).reduce(0,+) / Double(sleepData.count)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period picker
                    Picker("Период", selection: $selectedPeriod) {
                        Text("Неделя").tag(7)
                        Text("Месяц").tag(30)
                    }
                    .pickerStyle(.segmented).padding(.horizontal)

                    // Quality ring
                    ZStack {
                        Circle().stroke(Color.gray.opacity(0.2), lineWidth: 16)
                        Circle()
                            .trim(from: 0, to: avgQuality / 100)
                            .stroke(qualityColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 4) {
                            Text("\(Int(avgQuality))").font(.system(size: 44, weight: .bold)).foregroundColor(.white)
                            Text("Качество сна").font(.caption).foregroundColor(.gray)
                        }
                    }
                    .frame(width: 180, height: 180)

                    // Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Сред. длительность",
                                 value: String(format: "%.1f", avgDuration), unit: "часов",
                                 icon: "clock.fill", color: .blue)
                        StatCard(title: "Глубокий сон",
                                 value: sleepData.isEmpty ? "–"
                                    : String(format: "%.0f%%", sleepData.map(\.deepSleepPercent).reduce(0,+) / Double(sleepData.count)),
                                 unit: "в среднем", icon: "moon.stars.fill", color: .purple)
                    }
                    .padding(.horizontal)

                    // Sleep chart
                    if !sleepData.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Качество сна по дням").font(.headline).foregroundColor(.white)
                            Chart(sleepData) { night in
                                BarMark(
                                    x: .value("Дата", night.startDate, unit: .day),
                                    y: .value("Качество", night.qualityScore)
                                )
                                .foregroundStyle(qualityColor)
                                .cornerRadius(6)
                            }
                            .frame(height: 140)
                            .chartYScale(domain: 0...100)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Recommendations
                        SleepRecommendationsView(sleepData: sleepData.first)
                    }
                }
                .padding(.top)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Сон и восстановление")
            .onChange(of: selectedPeriod) { _ in loadSleep() }
        }
        .task { loadSleep() }
    }

    var qualityColor: Color {
        switch avgQuality {
        case 80...100: return .green
        case 60..<80:  return .yellow
        case 40..<60:  return .orange
        default:       return .red
        }
    }

    private func loadSleep() {
        Task {
            let fromHK = await healthKit.fetchSleepData(days: selectedPeriod)
            if fromHK.isEmpty {
                sleepData = repo.fetchSleepData(days: selectedPeriod)
            } else {
                fromHK.forEach { repo.saveSleepData($0) }
                sleepData = fromHK
            }
        }
    }
}

struct SleepRecommendationsView: View {
    let sleepData: SleepData?
    var tips: [String] {
        guard let sleep = sleepData else { return [] }
        var result: [String] = []
        if sleep.durationInHours < 7 { result.append("⚠️ Спите менее 7 часов — старайтесь ложиться на 30–60 мин раньше") }
        if sleep.deepSleepPercent < 15 { result.append("Мало глубокого сна — избегайте кофеина после 14:00") }
        if sleep.awakePercent > 10 { result.append("Часто просыпаетесь — поддерживайте прохладу в спальне (18–20°C)") }
        if result.isEmpty { result.append("✅ Показатели сна в норме. Продолжайте в том же духе!") }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Рекомендации").font(.headline).foregroundColor(.white)
            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(Color.blue).frame(width: 6, height: 6).padding(.top, 6)
                    Text(tip).font(.subheadline).foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Achievements View

struct AchievementsView: View {
    @State private var achievements: [Achievement] = []
    private let repo = WorkoutRepository()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(achievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Достижения")
        }
        .onAppear { achievements = repo.fetchAchievements() }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(achievement.isCompleted ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 56, height: 56)
                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(achievement.isCompleted ? .yellow : .gray)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(achievement.title).font(.subheadline).bold().foregroundColor(.white)
                Text(achievement.description).font(.caption).foregroundColor(.gray)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3)).frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(achievement.isCompleted ? Color.yellow : Color.blue)
                            .frame(width: geo.size.width * achievement.progressPercent, height: 6)
                    }
                }
                .frame(height: 6)
            }
            if achievement.isCompleted {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.yellow)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}
