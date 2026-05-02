//
//  GoalsView.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import SwiftUI

/// Экран целей и достижений
struct GoalsView: View {
    @StateObject private var goalsManager = GoalsManager.shared
    @State private var selectedTab = 0
    @State private var showCreateGoal = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Переключатель вкладок
                    Picker("", selection: $selectedTab) {
                        Text("Цели").tag(0)
                        Text("Достижения").tag(1)
                        Text("Прогресс").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            if selectedTab == 0 {
                                GoalsTabView(showCreateGoal: $showCreateGoal)
                            } else if selectedTab == 1 {
                                AchievementsTabView()
                            } else {
                                ProgressTabView()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Цели и достижения")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCreateGoal) {
                CreateGoalView()
            }
            .onAppear {
                goalsManager.updateAllGoals()
                goalsManager.checkAchievements()
            }
        }
    }
}

/// Вкладка целей
struct GoalsTabView: View {
    @StateObject private var goalsManager = GoalsManager.shared
    @Binding var showCreateGoal: Bool
    
    var activeGoals: [Goal] {
        goalsManager.goals.filter { $0.status == .active }
    }
    
    var completedGoals: [Goal] {
        goalsManager.goals.filter { $0.status == .completed }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Кнопка создания цели
            Button(action: { showCreateGoal = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Создать новую цель")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gradientPrimary)
                )
            }
            
            // Активные цели
            if !activeGoals.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Активные цели")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    ForEach(activeGoals) { goal in
                        GoalCard(goal: goal)
                    }
                }
            }
            
            // Выполненные цели
            if !completedGoals.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Выполненные")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    ForEach(completedGoals.prefix(5)) { goal in
                        GoalCard(goal: goal)
                    }
                }
            }
            
            if activeGoals.isEmpty && completedGoals.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("Нет целей")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Создайте свою первую цель для отслеживания прогресса")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
}

/// Карточка цели
struct GoalCard: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(goal.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                } else {
                    Text("\(goal.daysRemaining) дн.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }
            
            // Прогресс-бар
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(goal.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Text("\(Int(goal.currentValue)) / \(Int(goal.targetValue))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: goal.isCompleted ? [.green, .green] : [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(goal.progress), height: 12)
                            .animation(.spring(), value: goal.progress)
                    }
                }
                .frame(height: 12)
            }
        }
        .padding()
        .boxingCard()
    }
}

/// Вкладка достижений
struct AchievementsTabView: View {
    @StateObject private var goalsManager = GoalsManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Статистика достижений
            HStack(spacing: 16) {
                AchievementStatCard(
                    title: "Разблокировано",
                    value: "\(goalsManager.achievements.filter { $0.isUnlocked }.count)",
                    total: "\(goalsManager.achievements.count)",
                    color: .green
                )
                
                AchievementStatCard(
                    title: "В процессе",
                    value: "\(goalsManager.achievements.filter { !$0.isUnlocked && $0.progress > 0 }.count)",
                    total: "",
                    color: .yellow
                )
            }
            
            // Достижения по категориям
            ForEach(AchievementCategory.allCases, id: \.self) { category in
                let categoryAchievements = goalsManager.achievements.filter { $0.category == category }
                
                if !categoryAchievements.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(category.rawValue)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(categoryAchievements) { achievement in
                                AchievementCard(achievement: achievement)
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Карточка достижения
struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        achievement.isUnlocked ?
                        LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 28))
                    .foregroundColor(achievement.isUnlocked ? .white : .white.opacity(0.3))
            }
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if !achievement.isUnlocked {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.yellow)
                                .frame(width: geometry.size.width * CGFloat(achievement.progress), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackgroundLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(achievement.isUnlocked ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}

/// Статистическая карточка достижений
struct AchievementStatCard: View {
    let title: String
    let value: String
    let total: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(color)
                
                if !total.isEmpty {
                    Text("/ \(total)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .boxingCard()
    }
}

/// Вкладка прогресса
struct ProgressTabView: View {
    @StateObject private var goalsManager = GoalsManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Уровень пользователя
            UserLevelCard(level: goalsManager.progressStats.level)
            
            // Статистика прогресса
            VStack(alignment: .leading, spacing: 16) {
                Text("Статистика")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ProgressStatBox(title: "Тренировок", value: "\(goalsManager.progressStats.totalWorkouts)", icon: "dumbbell.fill", color: .blue)
                    ProgressStatBox(title: "Калорий", value: String(format: "%.0f", goalsManager.progressStats.totalCalories), icon: "flame.fill", color: .orange)
                    ProgressStatBox(title: "Серия", value: "\(goalsManager.progressStats.currentStreak)", icon: "flame.fill", color: .red)
                    ProgressStatBox(title: "Рекорд", value: "\(goalsManager.progressStats.longestStreak)", icon: "star.fill", color: .yellow)
                }
            }
        }
    }
}

/// Карточка уровня пользователя
struct UserLevelCard: View {
    let level: UserLevel
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Уровень \(level.level)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(level.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(level.progress))
                        .stroke(Color.yellow, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(level.level)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Опыт до следующего уровня")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Text("\(level.experienceToNext) XP")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.yellow)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(level.progress), height: 12)
                    }
                }
                .frame(height: 12)
            }
        }
        .padding()
        .boxingCard()
    }
}

/// Бокс статистики прогресса
struct ProgressStatBox: View {
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
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.cardBackgroundLight)
        .cornerRadius(12)
    }
}

/// Экран создания цели
struct CreateGoalView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var goalsManager = GoalsManager.shared
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedType: GoalType = .workouts
    @State private var targetValue: String = ""
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var isRecurring = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Form {
                    Section("Основная информация") {
                        TextField("Название цели", text: $title)
                        TextField("Описание", text: $description)
                    }
                    
                    Section("Параметры") {
                        Picker("Тип цели", selection: $selectedType) {
                            ForEach(GoalType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        
                        TextField("Целевое значение", text: $targetValue)
                            .keyboardType(.decimalPad)
                        
                        DatePicker("Дата окончания", selection: $endDate, displayedComponents: .date)
                        
                        Toggle("Повторяющаяся цель", isOn: $isRecurring)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Новая цель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Создать") {
                        if let value = Double(targetValue), !title.isEmpty {
                            goalsManager.createGoal(
                                title: title,
                                description: description.isEmpty ? title : description,
                                type: selectedType,
                                targetValue: value,
                                endDate: endDate,
                                isRecurring: isRecurring
                            )
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    GoalsView()
}
