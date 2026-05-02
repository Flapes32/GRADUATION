//
//  HealthKitManager.swift
//  course work
//
//  Created by Apple on 14.12.2025.
//

import Foundation
import HealthKit
import Combine

/// Менеджер для работы с HealthKit
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var currentHeartRate: Double?
    @Published var heartRateHistory: [HeartRateData] = []
    
    private var heartRateQuery: HKQuery?
    
    private init() {
        checkAuthorization()
    }
    
    /// Проверка и запрос авторизации
    func checkAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit недоступен на этом устройстве")
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.workoutType()
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if let error = error {
                    print("Ошибка авторизации HealthKit: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Начать мониторинг сердечного ритма в реальном времени
    func startHeartRateMonitoring() {
        guard isAuthorized else {
            checkAuthorization()
            return
        }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            if let error = error {
                print("Ошибка запроса ЧСС: \(error.localizedDescription)")
                return
            }
            
            self?.processHeartRateSamples(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            if let error = error {
                print("Ошибка обновления ЧСС: \(error.localizedDescription)")
                return
            }
            
            self?.processHeartRateSamples(samples)
        }
        
        healthStore.execute(query)
        heartRateQuery = query
    }
    
    /// Остановить мониторинг сердечного ритма
    func stopHeartRateMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
    }
    
    /// Обработка образцов ЧСС
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        let heartRateData = samples.map { sample -> HeartRateData in
            let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
            let value = sample.quantity.doubleValue(for: heartRateUnit)
            return HeartRateData(value: value, timestamp: sample.startDate)
        }
        
        DispatchQueue.main.async { [weak self] in
            if let latest = heartRateData.last {
                self?.currentHeartRate = latest.value
            }
            self?.heartRateHistory.append(contentsOf: heartRateData)
        }
    }
    
    /// Получить историю ЧСС за период
    func fetchHeartRateHistory(startDate: Date, endDate: Date, completion: @escaping ([HeartRateData]) -> Void) {
        guard isAuthorized else {
            completion([])
            return
        }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { _, samples, error in
            if let error = error {
                print("Ошибка получения истории ЧСС: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let samples = samples as? [HKQuantitySample] else {
                completion([])
                return
            }
            
            let heartRateData = samples.map { sample -> HeartRateData in
                let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                let value = sample.quantity.doubleValue(for: heartRateUnit)
                return HeartRateData(value: value, timestamp: sample.startDate)
            }
            
            DispatchQueue.main.async {
                completion(heartRateData)
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Получить данные о сне за период
    func fetchSleepData(startDate: Date, endDate: Date, completion: @escaping ([SleepData]) -> Void) {
        guard isAuthorized else {
            completion([])
            return
        }
        
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { _, samples, error in
            if let error = error {
                print("Ошибка получения данных о сне: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let samples = samples as? [HKCategorySample] else {
                completion([])
                return
            }
            
            // Группировка по ночам
            var sleepSessions: [SleepData] = []
            var currentSession: (start: Date, phases: [SleepPhase])?
            
            for sample in samples {
                let phaseType = self.mapSleepCategory(sample.value)
                let phase = SleepPhase(
                    type: phaseType,
                    startDate: sample.startDate,
                    endDate: sample.endDate
                )
                
                if currentSession == nil {
                    currentSession = (sample.startDate, [phase])
                } else {
                    currentSession?.phases.append(phase)
                }
                
                // Если следующий сэмпл начинается с большим разрывом, завершаем сессию
                if let nextIndex = samples.firstIndex(where: { $0.startDate > sample.endDate }),
                   samples[nextIndex].startDate.timeIntervalSince(sample.endDate) > 3600 {
                    if let session = currentSession {
                        let sleepData = SleepData(
                            startDate: session.start,
                            endDate: session.phases.last?.endDate ?? session.start,
                            sleepPhases: session.phases
                        )
                        sleepSessions.append(sleepData)
                    }
                    currentSession = nil
                }
            }
            
            // Добавляем последнюю сессию
            if let session = currentSession {
                let sleepData = SleepData(
                    startDate: session.start,
                    endDate: session.phases.last?.endDate ?? session.start,
                    sleepPhases: session.phases
                )
                sleepSessions.append(sleepData)
            }
            
            DispatchQueue.main.async {
                completion(sleepSessions)
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Преобразование категории HealthKit в тип фазы сна
    private func mapSleepCategory(_ value: Int) -> SleepPhaseType {
        switch value {
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            return .rem
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
            return .deep
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
            return .light
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            return .awake
        default:
            return .light
        }
    }
}

