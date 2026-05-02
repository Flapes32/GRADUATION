//
//  LactatePredictor.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import Foundation
import CoreMotion
import Combine

/// Менеджер для прогнозирования уровня лактата
class LactatePredictor: ObservableObject {
    static let shared = LactatePredictor()
    
    @Published var currentLactateLevel: Double = 0.0
    @Published var lactateHistory: [LactateData] = []
    
    private let motionManager = CMMotionManager()
    private var accelerometerData: [CMAccelerometerData] = []
    private var gyroscopeData: [CMGyroData] = []
    private var lastHeartRate: Double?
    private var heartRateRecoveryRate: Double?
    
    private var maxHeartRate: Double = 200.0 // Будет рассчитываться на основе возраста
    private let lactateDecayRate: Double = 0.1 // Скорость снижения лактата в минуту отдыха
    
    private init() {
        setupMotionSensors()
    }
    
    /// Настройка датчиков движения
    private func setupMotionSensors() {
        guard motionManager.isAccelerometerAvailable else { return }
        guard motionManager.isGyroAvailable else { return }
        
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.gyroUpdateInterval = 0.1
    }
    
    /// Начать мониторинг движения
    func startMotionMonitoring() {
        guard motionManager.isAccelerometerAvailable && motionManager.isGyroAvailable else {
            print("Датчики движения недоступны")
            return
        }
        
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data else { return }
            self?.processAccelerometerData(data)
        }
        
        motionManager.startGyroUpdates(to: .main) { [weak self] data, error in
            guard let data = data else { return }
            self?.processGyroscopeData(data)
        }
    }
    
    /// Остановить мониторинг движения
    func stopMotionMonitoring() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
    }
    
    /// Обработка данных акселерометра
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        accelerometerData.append(data)
        
        // Ограничиваем размер массива
        if accelerometerData.count > 100 {
            accelerometerData.removeFirst()
        }
    }
    
    /// Обработка данных гироскопа
    private func processGyroscopeData(_ data: CMGyroData) {
        gyroscopeData.append(data)
        
        // Ограничиваем размер массива
        if gyroscopeData.count > 100 {
            gyroscopeData.removeFirst()
        }
    }
    
    /// Обновить прогноз лактата на основе текущих данных
    func updateLactatePrediction(heartRate: Double?, recoveryRate: Double? = nil, isRestPeriod: Bool = false) {
        lastHeartRate = heartRate
        heartRateRecoveryRate = recoveryRate
        
        let predictedLactate = calculateLactateLevel(
            heartRate: heartRate,
            recoveryRate: recoveryRate,
            isRestPeriod: isRestPeriod
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.currentLactateLevel = predictedLactate
            
            let lactateData = LactateData(
                predictedValue: predictedLactate,
                timestamp: Date()
            )
            self?.lactateHistory.append(lactateData)
        }
    }
    
    /// Расчет уровня лактата
    private func calculateLactateLevel(heartRate: Double?, recoveryRate: Double?, isRestPeriod: Bool) -> Double {
        var lactateLevel = currentLactateLevel
        
        if isRestPeriod {
            // Во время отдыха лактат снижается
            lactateLevel = max(0.0, lactateLevel - lactateDecayRate * 0.1)
        } else if let hr = heartRate {
            // Во время активности лактат увеличивается на основе ЧСС и интенсивности движений
            let intensityFactor = calculateIntensityFactor()
            let heartRateFactor = calculateHeartRateFactor(heartRate: hr)
            
            let lactateIncrease = (intensityFactor * 0.3 + heartRateFactor * 0.7) * 0.1
            lactateLevel = min(1.0, lactateLevel + lactateIncrease)
        }
        
        // Учитываем скорость восстановления ЧСС
        if let recovery = recoveryRate, recovery > 0 {
            // Быстрое восстановление ЧСС указывает на хорошую способность выведения лактата
            let recoveryBonus = min(0.2, recovery / 10.0) // Максимум 0.2 снижения
            lactateLevel = max(0.0, lactateLevel - recoveryBonus)
        }
        
        return max(0.0, min(1.0, lactateLevel))
    }
    
    /// Расчет фактора интенсивности на основе данных акселерометра и гироскопа
    private func calculateIntensityFactor() -> Double {
        guard !accelerometerData.isEmpty else { return 0.5 }
        
        // Анализируем последние 10 секунд данных
        let recentData = accelerometerData.suffix(100)
        
        var totalAcceleration: Double = 0.0
        var peakCount: Int = 0
        
        for data in recentData {
            let magnitude = sqrt(
                pow(data.acceleration.x, 2) +
                pow(data.acceleration.y, 2) +
                pow(data.acceleration.z, 2)
            )
            totalAcceleration += magnitude
            
            // Считаем пики (взрывные движения)
            if magnitude > 1.5 {
                peakCount += 1
            }
        }
        
        let averageAcceleration = totalAcceleration / Double(recentData.count)
        let peakRatio = Double(peakCount) / Double(recentData.count)
        
        // Комбинируем среднюю интенсивность и частоту пиков
        return min(1.0, (averageAcceleration * 0.6 + peakRatio * 0.4))
    }
    
    /// Расчет фактора на основе ЧСС
    private func calculateHeartRateFactor(heartRate: Double) -> Double {
        guard maxHeartRate > 0 else { return 0.5 }
        
        let percentageOfMax = heartRate / maxHeartRate
        
        // Нелинейная зависимость: при высоком проценте ЧСС лактат растет быстрее
        if percentageOfMax < 0.5 {
            return percentageOfMax * 0.5
        } else if percentageOfMax < 0.85 {
            return 0.25 + (percentageOfMax - 0.5) * 1.5
        } else {
            // При ЧСС > 85% от максимума лактат растет очень быстро
            return 0.775 + (percentageOfMax - 0.85) * 1.5
        }
    }
    
    /// Установить максимальный ЧСС
    func setMaxHeartRate(_ maxHR: Double) {
        maxHeartRate = maxHR
    }
    
    /// Получить текущий уровень закисления
    func getCurrentLactateLevel() -> LactateLevel {
        return LactateLevel.fromValue(currentLactateLevel)
    }
    
    /// Сброс данных
    func reset() {
        currentLactateLevel = 0.0
        lactateHistory.removeAll()
        accelerometerData.removeAll()
        gyroscopeData.removeAll()
        lastHeartRate = nil
        heartRateRecoveryRate = nil
    }
}

