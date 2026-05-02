import SwiftUI

// MARK: - Watch App Entry

@main
struct BoxingTrackerWatchApp: App {
    @StateObject private var connectivity = WatchConnectivityManager.shared
    @StateObject private var healthKit = WatchHealthKitManager.shared

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(connectivity)
                .environmentObject(healthKit)
                .task { await healthKit.requestAuthorization() }
        }
    }
}

// MARK: - Watch Content View

struct WatchContentView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        if connectivity.isWorkoutActive {
            WatchWorkoutView()
        } else {
            WatchIdleView()
        }
    }
}

// MARK: - Watch Idle View

struct WatchIdleView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @EnvironmentObject var healthKit: WatchHealthKitManager

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.boxing")
                .font(.system(size: 40))
                .foregroundColor(.red)

            Text("Боксёр")
                .font(.headline)
                .foregroundColor(.white)

            Text("Запустите тренировку\nна iPhone")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            // Current HR even outside workout
            HStack {
                Image(systemName: "heart.fill").foregroundColor(.red).font(.caption)
                Text("\(Int(healthKit.currentHeartRate)) уд/мин")
                    .font(.caption).foregroundColor(.white)
            }
        }
        .containerBackground(.black, for: .watch)
    }
}

// MARK: - Watch Workout View

struct WatchWorkoutView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @EnvironmentObject var healthKit: WatchHealthKitManager

    var hrPercent: Double {
        guard healthKit.currentHeartRate > 0 else { return 0 }
        return min(healthKit.currentHeartRate / Double(connectivity.maxHeartRate), 1.0)
    }

    var hrColor: Color {
        switch hrPercent {
        case ..<0.70: return .green
        case 0.70..<0.85: return .yellow
        case 0.85..<0.95: return .orange
        default: return .red
        }
    }

    var lactate: Double {
        // Same formula as iPhone side
        switch hrPercent {
        case ..<0.60: return 1.5
        case 0.60..<0.75: return 1.5 + (hrPercent - 0.60) / 0.15 * 2.5
        case 0.75..<0.85: return 4.0 + (hrPercent - 0.75) / 0.10 * 3.0
        case 0.85..<0.92: return 7.0 + (hrPercent - 0.85) / 0.07 * 3.0
        default: return min(10.0 + (hrPercent - 0.92) / 0.08 * 4.0, 14.0)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Phase label
                Text(connectivity.currentPhase)
                    .font(.caption2).bold()
                    .foregroundColor(.gray)

                // Heart Rate — big and central
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: hrPercent)
                        .stroke(hrColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(Int(healthKit.currentHeartRate))")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("уд/мин").font(.system(size: 9)).foregroundColor(.gray)
                    }
                }
                .frame(width: 110, height: 110)

                // Lactate + Calories
                HStack(spacing: 8) {
                    WatchMetricView(
                        icon: "drop.fill",
                        value: String(format: "%.1f", lactate),
                        unit: "лак.",
                        color: .purple
                    )
                    WatchMetricView(
                        icon: "flame.fill",
                        value: "\(Int(healthKit.totalCalories))",
                        unit: "ккал",
                        color: .orange
                    )
                }

                // Recovery status
                let status = recoveryStatus(lactate: lactate)
                Text(status.0)
                    .font(.caption2).bold()
                    .foregroundColor(status.1)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(status.1.opacity(0.2))
                    .cornerRadius(8)

                // Stop button
                Button {
                    Task {
                        await healthKit.stopWorkout()
                        connectivity.sendStopWorkout()
                    }
                } label: {
                    Text("Стоп")
                        .font(.caption).bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .containerBackground(.black, for: .watch)
        .task {
            try? await healthKit.startWorkout()
        }
    }

    private func recoveryStatus(lactate: Double) -> (String, Color) {
        switch lactate {
        case ..<4:  return ("Готов", .green)
        case 4..<8: return ("Умеренно", .yellow)
        case 8..<12: return ("Устал", .orange)
        default: return ("Критично", .red)
        }
    }
}

// MARK: - Watch Metric View

struct WatchMetricView: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.caption2).foregroundColor(color)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(unit).font(.system(size: 9)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}
