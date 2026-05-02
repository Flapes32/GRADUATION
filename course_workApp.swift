import SwiftUI

@main
struct BoxingTrackerApp: App {
    @StateObject private var workoutManager = WorkoutManager.shared
    @StateObject private var healthKit = HealthKitManager.shared
    @StateObject private var watchSession = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workoutManager)
                .environmentObject(healthKit)
                .environmentObject(watchSession)
                .environment(\.managedObjectContext, PersistenceController.shared.context)
                .task {
                    await healthKit.requestAuthorization()
                }
        }
    }
}
