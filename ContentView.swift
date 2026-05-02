import SwiftUI

struct ContentView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var healthKit: HealthKitManager

    var body: some View {
        TabView {
            MainView()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }

            WorkoutView()
                .tabItem {
                    Label("Тренировка", systemImage: "figure.boxing")
                }

            HeartRateMonitorView()
                .tabItem {
                    Label("ЧСС", systemImage: "heart.fill")
                }

            StatisticsView()
                .tabItem {
                    Label("Статистика", systemImage: "chart.bar.fill")
                }

            SleepAnalysisView()
                .tabItem {
                    Label("Сон", systemImage: "moon.fill")
                }

            AchievementsView()
                .tabItem {
                    Label("Достижения", systemImage: "trophy.fill")
                }
        }
        .accentColor(.red)
        .preferredColorScheme(.dark)
    }
}
