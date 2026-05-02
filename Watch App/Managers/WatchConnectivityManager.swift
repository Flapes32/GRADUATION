import WatchConnectivity
import Foundation
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var currentHeartRate: Double = 0
    @Published var currentLactate: Double = 0
    @Published var currentCalories: Double = 0
    @Published var currentPhase: String = "Разминка"
    @Published var isWorkoutActive: Bool = false
    @Published var maxHeartRate: Int = 190
    @Published var userWeight: Double = 75

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send to iPhone

    func sendHeartRateUpdate(_ hr: Double, lactate: Double, calories: Double) {
        guard WCSession.default.isReachable else {
            // Fallback: transferUserInfo for background delivery
            WCSession.default.transferUserInfo([
                WatchMessageKey.heartRate: hr,
                WatchMessageKey.lactate: lactate,
                WatchMessageKey.calories: calories
            ])
            return
        }
        WCSession.default.sendMessage([
            WatchMessageKey.heartRate: hr,
            WatchMessageKey.lactate: lactate,
            WatchMessageKey.calories: calories
        ], replyHandler: nil, errorHandler: nil)
    }

    func sendPhaseChange(_ phase: String) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage([WatchMessageKey.phase: phase],
                                       replyHandler: nil, errorHandler: nil)
    }

    func sendStopWorkout() {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage([WatchMessageKey.stopWorkout: true],
                                       replyHandler: nil, errorHandler: nil)
    }
}

// MARK: - WCSessionDelegate (watchOS)

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}

    // Receive commands from iPhone
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if message[WatchMessageKey.startWorkout] as? Bool == true {
                self.isWorkoutActive = true
                if let phase = message[WatchMessageKey.phase] as? String { self.currentPhase = phase }
                if let maxHR = message["maxHR"] as? Int { self.maxHeartRate = maxHR }
                if let weight = message["weight"] as? Double { self.userWeight = weight }
            }
            if message[WatchMessageKey.stopWorkout] as? Bool == true {
                self.isWorkoutActive = false
            }
            if let phase = message[WatchMessageKey.phase] as? String {
                self.currentPhase = phase
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        DispatchQueue.main.async {
            if let maxHR = context["maxHR"] as? Int { self.maxHeartRate = maxHR }
            if let weight = context["userWeight"] as? Double { self.userWeight = weight }
        }
    }
}
