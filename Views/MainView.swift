//
//  MainView.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import SwiftUI

/// Главный экран навигации приложения
struct MainView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var watchManager = WatchConnectivityManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }
                .tag(0)
            
            WorkoutView()
                .tabItem {
                    Label("Тренировка", systemImage: "figure.boxing")
                }
                .tag(1)
            
            HeartRateMonitorView()
                .tabItem {
                    Label("ЧСС", systemImage: "heart.fill")
                }
                .tag(2)
            
            StatisticsView()
                .tabItem {
                    Label("Статистика", systemImage: "chart.bar.fill")
                }
                .tag(3)
            
            CaloriesTrackerView()
                .tabItem {
                    Label("Калории", systemImage: "flame.fill")
                }
                .tag(4)
            
            SleepAnalysisView()
                .tabItem {
                    Label("Сон", systemImage: "moon.fill")
                }
                .tag(5)
            
            GoalsView()
                .tabItem {
                    Label("Цели", systemImage: "target")
                }
                .tag(6)
            
            WorkoutPlansView()
                .tabItem {
                    Label("Планы", systemImage: "list.bullet.rectangle")
                }
                .tag(7)
            
            AnalyticsView()
                .tabItem {
                    Label("Аналитика", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(8)
        }
        .accentColor(.yellow)
        .preferredColorScheme(.dark)
        .onAppear {
            checkHealthKitAuthorization()
            watchManager.checkWatchAvailability()
        }
    }
    
    private func checkHealthKitAuthorization() {
        if !healthKitManager.isAuthorized {
            healthKitManager.checkAuthorization()
        }
    }
}

/// Главная страница
struct HomeView: View {
    @StateObject private var workoutManager = WorkoutManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var watchManager = WatchConnectivityManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    WelcomeCard()
                    
                    // Статистика
                    StatsGridCard()
                    
                    QuickActionsCard()
                    
                    // Новый функционал: Цели, достижения и планы
                    GoalsProgressCard()
                    HomeActivePlanCard()
                    AchievementsPreviewCard()
                    
                    // Кнопка для загрузки тестовых данных (если их мало или слишком много - старая версия)
                    if workoutManager.workoutHistory.count < 5 || workoutManager.workoutHistory.count > 15 {
                        Button(action: {
                            workoutManager.reloadTestData()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Обновить данные (\(workoutManager.workoutHistory.count) → 10 тренировок)")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gradientSecondary)
                            )
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    if !workoutManager.workoutHistory.isEmpty {
                        RecentWorkoutsCard(workouts: workoutManager.workoutHistory)
                    }
                    
                    CurrentStatusCard(
                        heartRate: healthKitManager.currentHeartRate,
                        isAuthorized: healthKitManager.isAuthorized
                    )
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .boxingBackground()
            .navigationTitle("Боксерский трекер")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Принудительно проверяем и загружаем данные при появлении экрана
                // Если данных слишком много (старая версия) или их нет - перезагружаем
                if workoutManager.workoutHistory.count < 5 || workoutManager.workoutHistory.count > 15 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        workoutManager.reloadTestData()
                    }
                }
            }
        }
    }
}

/// Карточка приветствия
struct WelcomeCard: View {
    @State private var pulsate = false
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulsate ? 1.1 : 1.0)
                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulsate)
                
                Circle()
                    .fill(Color.yellow.opacity(0.6))
                    .frame(width: 65, height: 65)
                
                Image(systemName: "person.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
            }
            .onAppear { pulsate = true }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Добро пожаловать!")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Отслеживайте свои показатели")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .boxingCard()
    }
}

/// Сетка статистики
struct StatsGridCard: View {
    @StateObject private var workoutManager = WorkoutManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    var totalWorkouts: Int {
        workoutManager.workoutHistory.count
    }
    
    var totalTime: Int {
        workoutManager.workoutHistory.compactMap { $0.duration }.reduce(0) { $0 + Int($1) } / 60
    }
    
    var totalCalories: Double {
        let calories = workoutManager.workoutHistory.compactMap { $0.caloriesBurned }
        let total = calories.reduce(0, +)
        // Если калории не рассчитаны, показываем примерное значение
        return total > 0 ? total : Double(workoutManager.workoutHistory.count) * 800.0
    }
    
    var avgHeartRate: Double {
        let allHeartRates = workoutManager.workoutHistory.flatMap { $0.heartRateData }
        guard !allHeartRates.isEmpty else { return 0 }
        return allHeartRates.map { $0.value }.reduce(0, +) / Double(allHeartRates.count)
    }
    
    var maxHeartRate: Double {
        let allHeartRates = workoutManager.workoutHistory.flatMap { $0.heartRateData }
        return allHeartRates.map { $0.value }.max() ?? 0
    }
    
    var avgRecoveryTime: Double {
        let recoveries = workoutManager.workoutHistory.compactMap { $0.recoveryTime }
        guard !recoveries.isEmpty else { return 0 }
        return recoveries.reduce(0, +) / Double(recoveries.count) / 60 // в минутах
    }
    
    var avgWorkoutDuration: Double {
        let durations = workoutManager.workoutHistory.compactMap { $0.duration }
        guard !durations.isEmpty else { return 0 }
        return durations.reduce(0, +) / Double(durations.count) / 60 // в минутах
    }
    
    var avgWorkoutHeartRate: Double {
        // Средний ЧСС по тренировкам (среднее из средних значений каждой тренировки)
        let workoutAvgHRs = workoutManager.workoutHistory.compactMap { workout -> Double? in
            guard !workout.heartRateData.isEmpty else { return nil }
            let avg = workout.heartRateData.map { $0.value }.reduce(0, +) / Double(workout.heartRateData.count)
            return avg
        }
        guard !workoutAvgHRs.isEmpty else { return 0 }
        return workoutAvgHRs.reduce(0, +) / Double(workoutAvgHRs.count)
    }
    
    var workoutsThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return workoutManager.workoutHistory.filter { $0.startDate >= weekAgo }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Статистика")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatCard(
                    title: "Тренировки",
                    value: "\(totalWorkouts)",
                    icon: "dumbbell.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Время",
                    value: "\(totalTime)м",
                    icon: "clock.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Калории",
                    value: String(format: "%.0f", totalCalories),
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Макс. ЧСС",
                    value: String(format: "%.0f", maxHeartRate),
                    icon: "heart.circle.fill",
                    color: .pink
                )
                
                StatCard(
                    title: "Средняя длительность",
                    value: String(format: "%.0fм", avgWorkoutDuration),
                    icon: "timer",
                    color: .indigo
                )
                
                StatCard(
                    title: "ЧСС на тренировке",
                    value: String(format: "%.0f", avgWorkoutHeartRate),
                    icon: "waveform.path",
                    color: .purple
                )
                
                StatCard(
                    title: "Восстановление",
                    value: String(format: "%.1fм", avgRecoveryTime),
                    icon: "arrow.down.circle.fill",
                    color: .cyan
                )
                
                StatCard(
                    title: "За неделю",
                    value: "\(workoutsThisWeek)",
                    icon: "calendar",
                    color: .yellow
                )
            }
        }
        .padding()
        .boxingCard()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(10)
        .background(Color.cardBackgroundLight)
        .cornerRadius(15)
    }
}

/// Карточка быстрых действий
struct QuickActionsCard: View {
    @State private var showWorkout = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Быстрые действия")
                .font(.headline)
                .foregroundColor(.white)
            
            Button(action: { showWorkout = true }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gradientPrimary)
                        .frame(height: 60)
                        .shadow(color: .yellow.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    HStack(spacing: 15) {
                        Image(systemName: "timer")
                            .font(.title2)
                        
                        Text("НАЧАТЬ ТРЕНИРОВКУ")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                }
            }
            
        }
        .padding()
        .boxingCard()
        .sheet(isPresented: $showWorkout) {
            WorkoutView()
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.cardBackgroundLight)
            .cornerRadius(12)
        }
    }
}

/// Статус Apple Watch
struct WatchStatusCard: View {
    @StateObject private var watchManager = WatchConnectivityManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Apple Watch")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Circle()
                    .fill(watchManager.isReachable ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
            }
            
            HStack(spacing: 20) {
                StatusItem(
                    title: "Сопряжено",
                    value: watchManager.isPaired ? "Да" : "Нет",
                    icon: "applewatch",
                    isActive: watchManager.isPaired
                )
                
                StatusItem(
                    title: "Доступно",
                    value: watchManager.isReachable ? "Да" : "Нет",
                    icon: "wifi",
                    isActive: watchManager.isReachable
                )
                
                StatusItem(
                    title: "Установлено",
                    value: watchManager.isWatchAppInstalled ? "Да" : "Нет",
                    icon: "app.badge.checkmark",
                    isActive: watchManager.isWatchAppInstalled
                )
            }
            
            Button(action: {
                watchManager.checkWatchAvailability()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Обновить статус")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.3))
                .cornerRadius(10)
            }
        }
        .padding()
        .boxingCard()
    }
}

struct StatusItem: View {
    let title: String
    let value: String
    let icon: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isActive ? .green : .gray)
            
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(isActive ? .green : .gray)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Карточка последних тренировок
struct RecentWorkoutsCard: View {
    let workouts: [WorkoutSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Последние тренировки")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(workouts.count)")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(10)
            }
            
            VStack(spacing: 10) {
                ForEach(workouts.prefix(5)) { workout in
                    WorkoutSummaryRow(workout: workout)
                }
            }
        }
        .padding()
        .boxingCard()
    }
}

struct WorkoutSummaryRow: View {
    let workout: WorkoutSession
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(formatDate(workout.startDate))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let duration = workout.duration {
                    Text(formatDuration(duration))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Показываем калории тренировки (справа)
            let calories = workout.caloriesBurned ?? 800.0 // Если нет данных, показываем среднее значение
            VStack(alignment: .trailing, spacing: 3) {
                Text("Калории")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(Int(calories))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                Text("ккал")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(10)
        .background(Color.cardBackgroundLight)
        .cornerRadius(15)
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

/// Карточка текущего статуса
struct CurrentStatusCard: View {
    let heartRate: Double?
    let isAuthorized: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Текущий статус")
                .font(.headline)
                .foregroundColor(.white)
            
            if isAuthorized {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        if let hr = heartRate {
                            Text("\(Int(hr)) уд/мин")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Активный мониторинг")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("Ожидание данных...")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                }
                .padding(10)
                .boxingCard()
            } else {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                    }
                    
                    Text("Требуется авторизация HealthKit")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(10)
                .boxingCard()
            }
        }
    }
}

/// Карточка прогресса целей
struct GoalsProgressCard: View {
    @StateObject private var goalsManager = GoalsManager.shared
    
    var activeGoals: [Goal] {
        goalsManager.goals.filter { $0.status == .active }
    }
    
    var completedGoalsCount: Int {
        goalsManager.goals.filter { $0.status == .completed }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Цели")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink(destination: GoalsView()) {
                    Text("Все цели")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            
            if !activeGoals.isEmpty {
                VStack(spacing: 12) {
                    ForEach(activeGoals.prefix(2)) { goal in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text("\(Int(goal.currentValue)) / \(Int(goal.targetValue))")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Text("\(Int(goal.progress * 100))%")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                        }
                        .padding(12)
                        .background(Color.cardBackgroundLight)
                        .cornerRadius(12)
                    }
                }
            } else {
                HStack {
                    Text("Нет активных целей")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    NavigationLink(destination: GoalsView()) {
                        Text("Создать")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            if completedGoalsCount > 0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Выполнено: \(completedGoalsCount)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding()
        .boxingCard()
    }
}

/// Карточка активного плана для главного экрана
struct HomeActivePlanCard: View {
    @StateObject private var plansManager = WorkoutPlansManager.shared
    
    var body: some View {
        if let plan = plansManager.activePlan {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Активный план")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    NavigationLink(destination: WorkoutPlansView()) {
                        Text("Детали")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text("Неделя \(plan.currentWeek)/\(plan.totalWeeks)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text("\(Int(plan.progress * 100))%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(plan.progress), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding()
            .boxingCard()
        }
    }
}

/// Карточка предпросмотра достижений
struct AchievementsPreviewCard: View {
    @StateObject private var goalsManager = GoalsManager.shared
    
    var unlockedCount: Int {
        goalsManager.achievements.filter { $0.isUnlocked }.count
    }
    
    var totalCount: Int {
        goalsManager.achievements.count
    }
    
    var recentAchievements: [Achievement] {
        goalsManager.achievements
            .filter { $0.isUnlocked }
            .sorted { ($0.unlockedDate ?? Date.distantPast) > ($1.unlockedDate ?? Date.distantPast) }
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Достижения")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink(destination: GoalsView()) {
                    Text("Все")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            
            HStack {
                Text("\(unlockedCount) / \(totalCount)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.yellow)
                
                Spacer()
                
                Text("\(Int(Double(unlockedCount) / Double(totalCount) * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if !recentAchievements.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recentAchievements) { achievement in
                            AchievementPreviewItem(achievement: achievement)
                        }
                    }
                }
            }
        }
        .padding()
        .boxingCard()
    }
}

/// Элемент предпросмотра достижения
struct AchievementPreviewItem: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            Text(achievement.title)
                .font(.caption2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 60)
        }
    }
}

#Preview {
    MainView()
}
