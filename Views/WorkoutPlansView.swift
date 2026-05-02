//
//  WorkoutPlansView.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import SwiftUI

/// Экран планов тренировок
struct WorkoutPlansView: View {
    @StateObject private var plansManager = WorkoutPlansManager.shared
    @State private var selectedPlan: WorkoutPlan?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Активный план
                        if let activePlan = plansManager.activePlan {
                            ActivePlanCard(plan: activePlan)
                        }
                        
                        // Доступные планы
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Доступные планы")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            ForEach(plansManager.plans) { plan in
                                WorkoutPlanCard(plan: plan, isActive: plan.id == plansManager.activePlan?.id)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Планы тренировок")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedPlan) { plan in
                PlanDetailView(plan: plan)
            }
        }
    }
}

/// Карточка активного плана
struct ActivePlanCard: View {
    let plan: WorkoutPlan
    @StateObject private var plansManager = WorkoutPlansManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Активный план")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(plan.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(plan.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Неделя")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(plan.currentWeek)/\(plan.totalWeeks)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.yellow)
                }
            }
            
            // Прогресс
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Прогресс плана")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Text("\(Int(plan.progress * 100))%")
                        .font(.subheadline)
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
                                    colors: [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(plan.progress), height: 12)
                    }
                }
                .frame(height: 12)
            }
            
            // Тренировки на сегодня
            let todayWorkouts = plansManager.getTodayWorkouts()
            if !todayWorkouts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Тренировки на сегодня")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    ForEach(todayWorkouts) { workout in
                        TodayWorkoutRow(workout: workout)
                    }
                }
            }
        }
        .padding()
        .boxingCard()
    }
}

/// Карточка плана тренировки
struct WorkoutPlanCard: View {
    let plan: WorkoutPlan
    let isActive: Bool
    @StateObject private var plansManager = WorkoutPlansManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(plan.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isActive {
                    Text("АКТИВЕН")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.2))
                        )
                }
            }
            
            HStack(spacing: 20) {
                PlanInfoItem(icon: "calendar", text: "\(plan.duration) дней")
                PlanInfoItem(icon: "figure.boxing", text: "\(plan.workoutsPerWeek)/нед")
                PlanInfoItem(icon: "chart.bar.fill", text: plan.type.rawValue)
            }
            
            if !isActive {
                Button(action: {
                    plansManager.startPlan(plan)
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Начать план")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gradientPrimary)
                    )
                }
            }
        }
        .padding()
        .boxingCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isActive ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}

/// Информационный элемент плана
struct PlanInfoItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.yellow)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

/// Строка тренировки на сегодня
struct TodayWorkoutRow: View {
    let workout: PlanWorkout
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "figure.boxing")
                    .font(.system(size: 18))
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(workout.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(formatDuration(workout.duration))
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(12)
        .background(Color.cardBackgroundLight)
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) мин"
    }
}

/// Детальный экран плана
struct PlanDetailView: View {
    let plan: WorkoutPlan
    @Environment(\.dismiss) var dismiss
    @StateObject private var plansManager = WorkoutPlansManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Информация о плане
                        VStack(alignment: .leading, spacing: 12) {
                            Text(plan.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(plan.description)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            HStack(spacing: 20) {
                                DetailInfoItem(icon: "calendar", title: "Длительность", value: "\(plan.duration) дней")
                                DetailInfoItem(icon: "figure.boxing", title: "Тренировок", value: "\(plan.workoutsPerWeek)/нед")
                            }
                        }
                        .padding()
                        .boxingCard()
                        
                        // Тренировки по неделям
                        ForEach(1...plan.totalWeeks, id: \.self) { week in
                            WeekSection(plan: plan, week: week)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Детали плана")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Секция недели
struct WeekSection: View {
    let plan: WorkoutPlan
    let week: Int
    
    var weekWorkouts: [PlanWorkout] {
        plan.workouts.filter { $0.week == week }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Неделя \(week)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            ForEach(weekWorkouts) { workout in
                WorkoutDetailRow(workout: workout)
            }
        }
        .padding()
        .boxingCard()
    }
}

/// Строка деталей тренировки
struct WorkoutDetailRow: View {
    let workout: PlanWorkout
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(workout.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(workout.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                if workout.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Выполнено")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Text(formatDuration(workout.duration))
                .font(.subheadline)
                .foregroundColor(.yellow)
        }
        .padding(12)
        .background(Color.cardBackgroundLight)
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) мин"
    }
}

/// Информационный элемент деталей
struct DetailInfoItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.white.opacity(0.6))
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    WorkoutPlansView()
}
