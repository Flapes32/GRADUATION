import WatchConnectivity
import Combine
import Foundation

class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()

    @Published var isWatchReachable: Bool = false
    @Published var lastReceivedHeartRate: Double = 0
    @Published var lastReceivedLactate: Double = 0
    @Published var lastReceivedCalories: Double = 0
    @Published var lastReceivedHRV: Double = 0
    @Published var lastReceivedPhase: String = ""

    // Callbacks for real-time updates
    var onHeartRateUpdate: ((Double) -> Void)?
    var onPhaseUpdate: ((WorkoutPhase) -> Void)?
    var onWorkoutStopped: (() -> Void)?

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send to Watch

    func sendStartWorkout(phase: WorkoutPhase, userProfile: UserProfile) {
        guard isWatchReachable else { return }
        let message: [String: Any] = [
            WatchMessageKey.startWorkout: true,
            WatchMessageKey.phase: phase.rawValue,
            "maxHR": userProfile.maxHeartRate,
            "weight": userProfile.weight
        ]
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Send startWorkout error: \(error)")
        }
    }

    func sendStopWorkout() {
        guard isWatchReachable else { return }
        WCSession.default.sendMessage(
            [WatchMessageKey.stopWorkout: true],
            replyHandler: nil,
            errorHandler: { print("Send stopWorkout error: \($0)") }
        )
    }

    func sendPhaseUpdate(_ phase: WorkoutPhase) {
        guard isWatchReachable else { return }
        WCSession.default.sendMessage(
            [WatchMessageKey.phase: phase.rawValue],
            replyHandler: nil,
            errorHandler: nil
        )
    }

    func updateApplicationContext(userProfile: UserProfile) {
        guard WCSession.default.activationState == .activated else { return }
        let context: [String: Any] = [
            "userName": userProfile.name,
            "userAge": userProfile.age,
            "userWeight": userProfile.weight,
            "maxHR": userProfile.maxHeartRate
        ]
        try? WCSession.default.updateApplicationContext(context)
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    // Receiving real-time data from Watch
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if let hr = message[WatchMessageKey.heartRate] as? Double {
                self.lastReceivedHeartRate = hr
                self.onHeartRateUpdate?(hr)
            }
            if let lactate = message[WatchMessageKey.lactate] as? Double {
                self.lastReceivedLactate = lactate
            }
            if let calories = message[WatchMessageKey.calories] as? Double {
                self.lastReceivedCalories = calories
            }
            if let hrv = message[WatchMessageKey.hrv] as? Double {
                self.lastReceivedHRV = hrv
            }
            if let phaseRaw = message[WatchMessageKey.phase] as? String,
               let phase = WorkoutPhase(rawValue: phaseRaw) {
                self.lastReceivedPhase = phaseRaw
                self.onPhaseUpdate?(phase)
            }
            if message[WatchMessageKey.stopWorkout] as? Bool == true {
                self.onWorkoutStopped?()
            }
        }
    }

    // Receiving background data from Watch (transferUserInfo)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        DispatchQueue.main.async {
            if let hr = userInfo[WatchMessageKey.heartRate] as? Double {
                self.lastReceivedHeartRate = hr
            }
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}
