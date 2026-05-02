import SwiftUI
import HealthKit

struct WorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var healthKit: HealthKitManager
    @State private var showingStopAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if workoutManager.isWorkoutActive {
                    ActiveWorkoutView(showingStopAlert: $showingStopAlert)
                } else {
                    StartWorkoutView()
                }
            }
            .navigationTitle("Тренировка")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Завершить тренировку?", isPresented: $showingStopAlert) {
                Button("Завершить", role: .destructive) {
                    Task { await workoutManager.stopWorkout() }
                }
                Button("Отмена", role: .cancel) {}
            }
        }
    }
}

// MARK: - Start Workout

struct StartWorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var selectedPhase: WorkoutPhase = .warmup

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "figure.boxing")
                .font(.system(size: 80))
                .foregroundColor(.red)

            Text("Готов к бою?")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            // Phase picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Начать с фазы:").font(.subheadline).foregroundColor(.gray)
                Picker("Фаза", selection: $selectedPhase) {
                    ForEach(WorkoutPhase.allCases, id: \.self) { phase in
                        Text(phase.rawValue).tag(phase)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)

            Button {
                Task { await workoutManager.startWorkout(phase: selectedPhase) }
            } label: {
                Text("НАЧАТЬ ТРЕНИРОВКУ")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(16)
            }
            .padding(.horizontal)

            Spacer()
        }
    }
}

// MARK: - Active Workout

struct ActiveWorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var healthKit: HealthKitManager
    @Binding var showingStopAlert: Bool

    var hrPercent: Double {
        guard workoutManager.currentHeartRate > 0 else { return 0 }
        return min(workoutManager.currentHeartRate / 190, 1.0)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Timer + phase
                HStack {
                    VStack(alignment: .leading) {
                        Text(workoutManager.currentPhase.rawValue)
                            .font(.title2).bold().foregroundColor(.white)
                        Text("Раунд \(workoutManager.currentRound)")
                            .font(.subheadline).foregroundColor(.gray)
                    }
                    Spacer()
                    Text(formatTime(workoutManager.elapsedTime))
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(16)
                .padding(.horizontal)

                // Heart Rate Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    Circle()
                        .trim(from: 0, to: hrPercent)
                        .stroke(hrColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: hrPercent)
                    VStack(spacing: 4) {
                        Text("\(Int(workoutManager.currentHeartRate))")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("уд/мин").font(.subheadline).foregroundColor(.gray)
                        Text("\(Int(hrPercent * 100))% от макс.")
                            .font(.caption).foregroundColor(hrColor)
                    }
                }
                .frame(width: 220, height: 220)
                .padding()

                // Lactate + peaks
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    LactateCard(manager: workoutManager.lactatePredictor)
                    StatCard(title: "Пиковых нагрузок", value: "\(workoutManager.peakHeartRates)",
                             unit: "раз", icon: "bolt.fill", color: .yellow)
                }
                .padding(.horizontal)

                // Phase buttons
                VStack(alignment: .leading, spacing: 8) {
                    Text("Сменить фазу").font(.subheadline).foregroundColor(.gray)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                        GridItem(.flexible())], spacing: 8) {
                        ForEach(WorkoutPhase.allCases, id: \.self) { phase in
                            PhaseButton(phase: phase,
                                        isSelected: workoutManager.currentPhase == phase) {
                                workoutManager.changePhase(phase)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Stop button
                Button {
                    showingStopAlert = true
                } label: {
                    Text("ЗАВЕРШИТЬ")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding(.top)
        }
    }

    var hrColor: Color {
        switch hrPercent {
        case ..<0.70: return .green
        case 0.70..<0.85: return .yellow
        case 0.85..<0.95: return .orange
        default: return .red
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60; let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Lactate Card

struct LactateCard: View {
    @ObservedObject var manager: LactatePredictor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "drop.fill").foregroundColor(.purple)
                Text("Лактат").font(.caption).foregroundColor(.gray)
            }
            Text(String(format: "%.1f", manager.currentLactate))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("ммоль/л").font(.caption2).foregroundColor(.gray)

            Text(manager.recoveryStatus.rawValue)
                .font(.caption).bold()
                .foregroundColor(statusColor)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(16)
    }

    var statusColor: Color {
        switch manager.recoveryStatus {
        case .ready: return .green
        case .moderate: return .yellow
        case .tired: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Phase Button

struct PhaseButton: View {
    let phase: WorkoutPhase
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(phase.rawValue)
                .font(.caption).bold()
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.red : Color.gray.opacity(0.2))
                .cornerRadius(10)
        }
    }
}
