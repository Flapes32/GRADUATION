//
//  WatchConnectivityManager.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import Foundation
import WatchConnectivity
import Combine

/// Менеджер для работы с WatchConnectivity
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isPaired: Bool = false
    @Published var isReachable: Bool = false
    @Published var isWatchAppInstalled: Bool = false
    @Published var latestWorkoutData: WatchWorkoutData? = nil
    @Published var isWorkoutInProgress: Bool = false
    @Published var workoutDataHistory: [WatchWorkoutData] = []
    
    private let maxHistoryPoints = 100
    private var currentWorkoutId: String?
    
    private override init() {
        super.init()
        activateSession()
    }
    
    private func activateSession() {
        guard WCSession.isSupported() else {
            print("WCSession не поддерживается на этом устройстве")
            return
        }
        
        let session = WCSession.default
        session.delegate = self
        
        DispatchQueue.main.async {
            session.activate()
            print("WCSession активирован")
        }
    }
    
    func checkWatchAvailability() {
        guard WCSession.isSupported() else { return }
        
        let session = WCSession.default
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isPaired = session.isPaired
            self.isReachable = session.isReachable
            self.isWatchAppInstalled = session.isWatchAppInstalled
            
            print("Watch статус: paired=\(session.isPaired), reachable=\(session.isReachable), installed=\(session.isWatchAppInstalled)")
        }
    }
    
    func sendWorkoutData(_ data: WatchWorkoutData) {
        guard WCSession.isSupported(), WCSession.default.isReachable else {
            print("Watch недоступен")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(data)
            let message = ["workoutData": data]
            
            WCSession.default.sendMessage(message, replyHandler: { reply in
                print("Данные отправлены: \(reply)")
            }, errorHandler: { error in
                print("Ошибка отправки: \(error.localizedDescription)")
            })
        } catch {
            print("Ошибка кодирования: \(error.localizedDescription)")
        }
    }
    
    func startWorkout() {
        currentWorkoutId = UUID().uuidString
        isWorkoutInProgress = true
        sendCommand(.startWorkout)
    }
    
    func stopWorkout() {
        sendCommand(.stopWorkout)
        currentWorkoutId = nil
        isWorkoutInProgress = false
    }
    
    private func sendCommand(_ command: WatchCommand) {
        guard WCSession.isSupported(), WCSession.default.isReachable else { return }
        
        do {
            let message = WatchMessage(command: command)
            let data = try JSONEncoder().encode(message)
            let messageDict = ["message": data]
            
            WCSession.default.sendMessage(messageDict, replyHandler: { reply in
                print("Команда \(command) отправлена: \(reply)")
            }, errorHandler: { error in
                print("Ошибка отправки команды: \(error.localizedDescription)")
            })
        } catch {
            print("Ошибка кодирования команды: \(error.localizedDescription)")
        }
    }
    
    private func processWorkoutData(_ data: WatchWorkoutData) {
        DispatchQueue.main.async {
            self.latestWorkoutData = data
            self.isWorkoutInProgress = data.isInProgress
            
            self.workoutDataHistory.append(data)
            
            if self.workoutDataHistory.count > self.maxHistoryPoints {
                self.workoutDataHistory.removeFirst(self.workoutDataHistory.count - self.maxHistoryPoints)
            }
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isPaired = session.isPaired
            self.isReachable = session.isReachable
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession стал неактивным")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession деактивирован")
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleReceivedMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleReceivedMessage(message)
        replyHandler(["status": "received"])
    }
    
    private func handleReceivedMessage(_ message: [String: Any]) {
        if let data = message["workoutData"] as? Data {
            do {
                let workoutData = try JSONDecoder().decode(WatchWorkoutData.self, from: data)
                processWorkoutData(workoutData)
            } catch {
                print("Ошибка декодирования: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Watch Data Models
struct WatchWorkoutData: Codable {
    let timestamp: TimeInterval
    let heartRate: Double
    let activeEnergy: Double
    let workoutDuration: Double
    let steps: Int
    let distance: Double
    let rounds: Int
    let isInProgress: Bool
    let avgHeartRate: Double
    let maxHeartRate: Double
    let restingHeartRate: Double?
    let workoutId: String
}

enum WatchCommand: String, Codable {
    case startWorkout
    case pauseWorkout
    case resumeWorkout
    case stopWorkout
    case updateSettings
    case requestData
    case syncExercises
}

struct WatchMessage: Codable {
    let command: WatchCommand
    let data: Data?
    
    init(command: WatchCommand, data: Data? = nil) {
        self.command = command
        self.data = data
    }
}

