import SwiftUI

struct MainView: View {
    @EnvironmentObject var healthKit: HealthKitManager
    @EnvironmentObject var watchSession: WatchSessionManager
    @State private var restingHR: Double = 0
    @State private var hrv: Double = 0
    @State private var recentWorkouts: [WorkoutSession] = []
    private let repo = WorkoutRepository()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Watch status
                    WatchStatusBanner()

                    // Quick stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "ЧСС покоя", value: "\(Int(restingHR))", unit: "уд/мин",
                                 icon: "heart.fill", color: .red)
                        StatCard(title: "HRV", value: String(format: "%.0f", hrv), unit: "мс",
                                 icon: "waveform.path", color: .purple)
                        StatCard(title: "Тренировок", value: "\(repo.totalWorkoutsCount())", unit: "всего",
                                 icon: "dumbbell.fill", color: .blue)
                        StatCard(title: "Калорий", value: "\(Int(repo.totalCaloriesBurned()))", unit: "ккал",
                                 icon: "flame.fill", color: .orange)
                    }
                    .padding(.horizontal)

                    // Recent workouts
                    if !recentWorkouts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Последние тренировки")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)

                            ForEach(recentWorkouts.prefix(3)) { workout in
                                WorkoutRowView(workout: workout)
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Боксёр")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            restingHR = await healthKit.fetchRestingHeartRate()
            hrv = await healthKit.fetchHRV()
            recentWorkouts = repo.fetchWorkouts(limit: 5)
        }
    }
}

// MARK: - Watch Status Banner

struct WatchStatusBanner: View {
    @EnvironmentObject var watchSession: WatchSessionManager

    var body: some View {
        HStack {
            Image(systemName: watchSession.isWatchReachable ? "applewatch.radiowaves.left.and.right" : "applewatch")
                .foregroundColor(watchSession.isWatchReachable ? .green : .gray)
            Text(watchSession.isWatchReachable ? "Apple Watch подключены" : "Apple Watch не найдены")
                .font(.subheadline)
                .foregroundColor(watchSession.isWatchReachable ? .green : .gray)
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Text(title).font(.caption).foregroundColor(.gray)
            }
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(unit).font(.caption2).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Workout Row

struct WorkoutRowView: View {
    let workout: WorkoutSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.phase.rawValue)
                    .font(.subheadline).bold()
                    .foregroundColor(.white)
                Text(workout.startDate, style: .date)
                    .font(.caption).foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(workout.averageHeartRate)) уд/мин")
                    .font(.subheadline).foregroundColor(.red)
                Text(formatDuration(workout.duration))
                    .font(.caption).foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
