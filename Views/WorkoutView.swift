//
//  WorkoutView.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import SwiftUI

/// Экран тренировки с отображением метрик в реальном времени
struct WorkoutView: View {
    @StateObject private var workoutManager = WorkoutManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var lactatePredictor = LactatePredictor.shared
    
    @State private var timer: Timer?
    @State private var workoutTime: TimeInterval = 0
    
    // Демонстрационные данные для наглядности
    @State private var demoHeartRate: Double = 165.0
    @State private var demoLactate: Double = 0.65
    @State private var demoPeakLoads: Int = 3
    @State private var demoRecovery: HeartRateRecovery?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Кнопка запуска тренировки (если не запущена)
                        if workoutManager.currentSession == nil {
                            StartWorkoutButton {
                                startWorkout()
                            }
                        } else {
                            // Заголовок с таймером
                            WorkoutHeader(time: workoutTime)
                        }
                        
                        // Показываем метрики только если тренировка запущена
                        if workoutManager.currentSession != nil {
                            // Текущая ЧСС (используем демо-данные если нет реальных)
                            let displayHeartRate = healthKitManager.currentHeartRate ?? demoHeartRate
                            HeartRateCard(
                                heartRate: displayHeartRate,
                                phase: workoutManager.currentPhase
                            )
                            
                            // Индикатор закисления (используем демо-данные если нет реальных)
                            let displayLactate = lactatePredictor.currentLactateLevel > 0 ? lactatePredictor.currentLactateLevel : demoLactate
                            LactateIndicatorCard(
                                lactateLevel: displayLactate,
                                lactateStatus: lactatePredictor.getCurrentLactateLevel()
                            )
                            
                            // Счетчик пиковых нагрузок (используем демо-данные если нет реальных)
                            // Приоритет: реальные данные > демо-данные > 0
                            let displayPeakLoads = max(workoutManager.peakLoadCount, demoPeakLoads)
                            PeakLoadCard(count: displayPeakLoads)
                            
                            // Скорость падения ЧСС и статус восстановления
                            if workoutManager.currentPhase == .rest {
                                let displayRecovery = workoutManager.heartRateRecovery ?? demoRecovery
                                RecoveryCard(
                                    recovery: displayRecovery,
                                    status: workoutManager.recoveryStatus
                                )
                            }
                            
                            // Управление тренировкой
                            WorkoutControlsView(
                                currentPhase: workoutManager.currentPhase,
                                onPhaseChange: { phase in
                                    workoutManager.changePhase(phase)
                                },
                                onStartRest: {
                                    workoutManager.startRestPeriod()
                                }
                            )
                            
                            // Кнопка завершения
                            Button(action: {
                                workoutManager.endWorkout()
                                stopWorkout()
                            }) {
                                HStack {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 18))
                                    Text("Завершить тренировку")
                                        .font(.appHeadline())
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.gradientSecondary)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                        )
                                        .shadow(color: .red.opacity(0.5), radius: 20, x: 0, y: 10)
                                        .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 2)
                                )
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Тренировка")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                stopWorkout()
            }
        }
    }
    
    private func startWorkout() {
        workoutManager.startWorkout()
        
        // Инициализируем демонстрационные данные
        demoHeartRate = 120.0 // Начальный ЧСС
        demoLactate = 0.3 // Начальный лактат
        demoPeakLoads = 0 // Начинаем с 0 пиковых нагрузок
        demoRecovery = nil
        
        // Сбрасываем счетчик пиковых нагрузок в менеджере для демо
        if workoutManager.peakLoadCount == 0 {
            // Устанавливаем начальное значение для демонстрации
        }
        
        // Создаем демо-данные для восстановления
        demoRecovery = HeartRateRecovery(
            initialHeartRate: 185.0,
            heartRateAfter30Seconds: 165.0,
            timestamp: Date()
        )
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            workoutTime += 1.0
            
            // Обновляем демонстрационные данные для наглядности
            updateDemoData()
            
            // Используем демо-ЧСС если нет реальных данных
            let heartRateToUse = healthKitManager.currentHeartRate ?? demoHeartRate
            workoutManager.updateWorkoutData(heartRate: heartRateToUse)
            
            if workoutManager.currentPhase == .rest {
                workoutManager.updateRecoveryData()
            }
        }
    }
    
    /// Обновление демонстрационных данных для наглядности
    private func updateDemoData() {
        // Динамически изменяем ЧСС в зависимости от фазы
        switch workoutManager.currentPhase {
        case .warmup:
            // ЧСС постепенно растет от 120 до 140
            demoHeartRate = min(140, demoHeartRate + Double.random(in: 0.5...1.5))
        case .active:
            // ЧСС в рабочей зоне 150-170
            if demoHeartRate < 150 {
                demoHeartRate = 150 + Double.random(in: 0...20)
            } else {
                demoHeartRate = max(150, min(170, demoHeartRate + Double.random(in: -2...2)))
            }
            // Лактат растет
            demoLactate = min(0.85, demoLactate + Double.random(in: 0.01...0.03))
            // Пиковые нагрузки могут появиться при высоком ЧСС
            if demoHeartRate > 165 && Int.random(in: 0...100) < 8 { // 8% шанс при высоком ЧСС
                demoPeakLoads += 1
            }
        case .sprint:
            // ЧСС в максимальной зоне 180-195
            if demoHeartRate < 180 {
                demoHeartRate = 180 + Double.random(in: 0...15)
            } else {
                demoHeartRate = max(180, min(195, demoHeartRate + Double.random(in: -3...3)))
            }
            // Лактат быстро растет
            demoLactate = min(0.95, demoLactate + Double.random(in: 0.02...0.05))
            // Пиковые нагрузки часто появляются в спринте
            if Int.random(in: 0...100) < 25 { // 25% шанс в спринте
                demoPeakLoads += 1
            }
            // Также пиковые нагрузки при очень высоком ЧСС (>190)
            if demoHeartRate > 190 && Int.random(in: 0...100) < 30 { // 30% шанс при ЧСС >190
                demoPeakLoads += 1
            }
        case .rest:
            // ЧСС падает
            demoHeartRate = max(100, demoHeartRate - Double.random(in: 2...5))
            // Лактат медленно падает
            demoLactate = max(0.3, demoLactate - Double.random(in: 0.01...0.02))
        }
    }
    
    private func stopWorkout() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// Кнопка запуска тренировки
struct StartWorkoutButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gradientPrimary)
                    .frame(height: 80)
                    .shadow(color: .yellow.opacity(0.5), radius: 15, x: 0, y: 8)
                
                VStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                    
                    Text("НАЧАТЬ ТРЕНИРОВКУ")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
    }
}

/// Заголовок тренировки с таймером
struct WorkoutHeader: View {
    let time: TimeInterval
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Активная тренировка")
                    .font(.appHeadline())
                    .foregroundColor(.white.opacity(0.8))
                
                Text(formatTime(time))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.appPrimary.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: CGFloat(time.truncatingRemainder(dividingBy: 60)) / 60)
                    .stroke(Color.appPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
            }
        }
        .boxingCard()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// Карточка с отображением ЧСС
struct HeartRateCard: View {
    let heartRate: Double?
    let phase: WorkoutPhase
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Сердечный ритм")
                    .font(.appHeadline())
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.gradientHeart)
            }
            
            HStack(alignment: .bottom, spacing: 12) {
                Text(heartRate != nil ? "\(Int(heartRate!))" : "--")
                    .font(.appGiantNumber())
                    .foregroundStyle(Color.gradientHeart)
                
                Text("уд/мин")
                    .font(.appHeadline())
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 12)
                
                Spacer()
            }
            
            HStack {
                Image(systemName: phaseIcon)
                    .font(.system(size: 16))
                    .foregroundColor(phaseColor)
                
                Text(phase.rawValue)
                    .font(.appBody())
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(phaseColor.opacity(0.2))
            )
        }
        .boxingCard()
    }
    
    private var phaseIcon: String {
        switch phase {
        case .warmup: return "flame.fill"
        case .active: return "bolt.fill"
        case .sprint: return "gauge.high"
        case .rest: return "pause.circle.fill"
        }
    }
    
    private var phaseColor: Color {
        switch phase {
        case .warmup: return .orange
        case .active: return .blue
        case .sprint: return .red
        case .rest: return .green
        }
    }
}

/// Карточка индикатора закисления
struct LactateIndicatorCard: View {
    let lactateLevel: Double
    let lactateStatus: LactateLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Уровень закисления")
                    .font(.appHeadline())
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(lactateStatus.rawValue)
                    .font(.appCaption())
                    .foregroundColor(lactateColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(lactateColor.opacity(0.2))
                    )
            }
            
            // Визуальная шкала
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Фон
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 40)
                    
                    // Заполнение с градиентом
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [lactateColor.opacity(0.6), lactateColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(lactateLevel), height: 40)
                        .shadow(color: lactateColor.opacity(0.5), radius: 8, x: 0, y: 0)
                }
            }
            .frame(height: 40)
            
            HStack {
                Text("0%")
                    .font(.appCaption())
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Text("\(Int(lactateLevel * 100))%")
                    .font(.appHeadline())
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("100%")
                    .font(.appCaption())
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .boxingCard()
    }
    
    private var lactateColor: Color {
        switch lactateStatus {
        case .normal: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .peak: return .red
        }
    }
}

/// Карточка пиковых нагрузок
struct PeakLoadCard: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Пиковые нагрузки")
                    .font(.appHeadline())
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(alignment: .bottom, spacing: 8) {
                    Text("\(count)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("эпизодов")
                        .font(.appBody())
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 4)
                }
                
                Text("ЧСС > 95% от максимума")
                    .font(.appCaption())
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .boxingCard()
    }
}

/// Карточка восстановления
struct RecoveryCard: View {
    let recovery: HeartRateRecovery?
    let status: RecoveryStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Восстановление")
                .font(.appHeadline())
                .foregroundColor(.white.opacity(0.8))
            
            if let recovery = recovery {
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Падение ЧСС")
                            .font(.appCaption())
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("\(Int(recovery.dropRate))")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("уд/мин за 30 сек")
                            .font(.appCaption())
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(statusColor.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .fill(statusColor)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: statusIcon)
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                        
                        Text(status.rawValue)
                            .font(.appCaption())
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
            } else {
                HStack {
                    ProgressView()
                        .tint(.appPrimary)
                    
                    Text("Измерение...")
                        .font(.appBody())
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.leading, 12)
                    
                    Spacer()
                }
            }
        }
        .boxingCard()
    }
    
    private var statusColor: Color {
        switch status {
        case .ready: return .green
        case .partial: return .yellow
        case .risk: return .red
        }
    }
    
    private var statusIcon: String {
        switch status {
        case .ready: return "checkmark.circle.fill"
        case .partial: return "exclamationmark.circle.fill"
        case .risk: return "xmark.circle.fill"
        }
    }
}

/// Управление тренировкой
struct WorkoutControlsView: View {
    let currentPhase: WorkoutPhase
    let onPhaseChange: (WorkoutPhase) -> Void
    let onStartRest: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Управление")
                .font(.appHeadline())
                .foregroundColor(.white.opacity(0.8))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                PhaseButton(phase: .warmup, current: currentPhase, action: onPhaseChange)
                PhaseButton(phase: .active, current: currentPhase, action: onPhaseChange)
                PhaseButton(phase: .sprint, current: currentPhase, action: onPhaseChange)
            }
            
            Button(action: onStartRest) {
                HStack {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 20))
                    Text("Отдых")
                        .font(.appHeadline())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appPrimary.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.appPrimary, lineWidth: 2)
                        )
                )
            }
        }
        .boxingCard()
    }
}

struct PhaseButton: View {
    let phase: WorkoutPhase
    let current: WorkoutPhase
    let action: (WorkoutPhase) -> Void
    
    var isSelected: Bool { phase == current }
    
    var body: some View {
        Button(action: { action(phase) }) {
            VStack(spacing: 8) {
                Image(systemName: phaseIcon)
                    .font(.system(size: 24))
                
                Text(phase.rawValue)
                    .font(.appCaption())
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.appPrimary : Color.cardBackgroundLight.opacity(0.5))
            )
        }
    }
    
    private var phaseIcon: String {
        switch phase {
        case .warmup: return "flame.fill"
        case .active: return "bolt.fill"
        case .sprint: return "gauge.high"
        case .rest: return "pause.circle.fill"
        }
    }
}

#Preview {
    WorkoutView()
}
