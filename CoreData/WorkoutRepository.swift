import CoreData
import Foundation

// MARK: - Persistence Controller

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "BoxingTracker")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData load failed: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var context: NSManagedObjectContext { container.viewContext }

    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("CoreData save error: \(error)")
        }
    }
}

// MARK: - Workout Repository

class WorkoutRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.context) {
        self.context = context
    }

    // MARK: Save Workout

    func saveWorkout(_ session: WorkoutSession) {
        let entity = CDWorkoutSession(context: context)
        entity.id             = session.id
        entity.startDate      = session.startDate
        entity.endDate        = session.endDate
        entity.duration       = session.duration
        entity.averageHR      = session.averageHeartRate
        entity.maxHR          = session.maxHeartRate
        entity.minHR          = session.minHeartRate
        entity.totalCalories  = session.totalCalories
        entity.averageHRV     = session.averageHRV
        entity.peakLactate    = session.peakLactate
        entity.phase          = session.phase.rawValue

        // Save HR records
        for round in session.rounds {
            let roundEntity = CDRoundData(context: context)
            roundEntity.id            = round.id
            roundEntity.number        = Int16(round.number)
            roundEntity.duration      = round.duration
            roundEntity.averageHR     = round.averageHeartRate
            roundEntity.maxHR         = round.maxHeartRate
            roundEntity.peakLactate   = round.peakLactate
            roundEntity.calories      = round.calories
            roundEntity.startDate     = round.startDate
            roundEntity.endDate       = round.endDate
            roundEntity.workout       = entity
        }

        PersistenceController.shared.save()
    }

    // MARK: Fetch Workouts

    func fetchWorkouts(limit: Int? = nil) -> [WorkoutSession] {
        let request = CDWorkoutSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        if let limit = limit { request.fetchLimit = limit }

        do {
            let results = try context.fetch(request)
            return results.map { mapToSession($0) }
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    func fetchWorkouts(from startDate: Date, to endDate: Date) -> [WorkoutSession] {
        let request = CDWorkoutSession.fetchRequest()
        request.predicate = NSPredicate(format: "startDate >= %@ AND startDate <= %@",
                                        startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]

        do {
            return try context.fetch(request).map { mapToSession($0) }
        } catch {
            return []
        }
    }

    func deleteWorkout(id: UUID) {
        let request = CDWorkoutSession.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let result = try? context.fetch(request).first {
            context.delete(result)
            PersistenceController.shared.save()
        }
    }

    // MARK: Heart Rate Records

    func saveHeartRateRecords(_ records: [HeartRateRecord]) {
        for record in records {
            let entity = CDHeartRateRecord(context: context)
            entity.id              = record.id
            entity.value           = record.value
            entity.timestamp       = record.timestamp
            entity.workoutSessionId = record.workoutSessionId
        }
        PersistenceController.shared.save()
    }

    func fetchHeartRateRecords(for workoutId: UUID) -> [HeartRateRecord] {
        let request = CDHeartRateRecord.fetchRequest()
        request.predicate = NSPredicate(format: "workoutSessionId == %@", workoutId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            return try context.fetch(request).map {
                HeartRateRecord(value: $0.value, timestamp: $0.timestamp ?? Date(),
                                workoutSessionId: $0.workoutSessionId)
            }
        } catch { return [] }
    }

    // MARK: Sleep Data

    func saveSleepData(_ sleep: SleepData) {
        let entity = CDSleepData(context: context)
        entity.id               = sleep.id
        entity.startDate        = sleep.startDate
        entity.endDate          = sleep.endDate
        entity.durationHours    = sleep.durationInHours
        entity.deepSleepPercent = sleep.deepSleepPercent
        entity.remSleepPercent  = sleep.remSleepPercent
        entity.awakePercent     = sleep.awakePercent
        entity.qualityScore     = sleep.qualityScore
        PersistenceController.shared.save()
    }

    func fetchSleepData(days: Int = 7) -> [SleepData] {
        let from = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let request = CDSleepData.fetchRequest()
        request.predicate = NSPredicate(format: "startDate >= %@", from as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]

        do {
            return try context.fetch(request).map {
                var s = SleepData(startDate: $0.startDate ?? Date(), endDate: $0.endDate ?? Date())
                s.deepSleepPercent = $0.deepSleepPercent
                s.remSleepPercent  = $0.remSleepPercent
                s.awakePercent     = $0.awakePercent
                s.qualityScore     = $0.qualityScore
                return s
            }
        } catch { return [] }
    }

    // MARK: Achievements

    func fetchAchievements() -> [Achievement] {
        let request = CDAchievement.fetchRequest()
        do {
            return try context.fetch(request).map {
                var a = Achievement(title: $0.title ?? "", description: $0.desc ?? "",
                                    icon: $0.icon ?? "", total: $0.total)
                a.progress      = $0.progress
                a.isCompleted   = $0.isCompleted
                a.completedDate = $0.completedDate
                return a
            }
        } catch { return defaultAchievements() }
    }

    func updateAchievement(_ achievement: Achievement) {
        let request = CDAchievement.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", achievement.title)

        if let existing = try? context.fetch(request).first {
            existing.progress      = achievement.progress
            existing.isCompleted   = achievement.isCompleted
            existing.completedDate = achievement.completedDate
        } else {
            let entity = CDAchievement(context: context)
            entity.id           = achievement.id
            entity.title        = achievement.title
            entity.desc         = achievement.description
            entity.icon         = achievement.icon
            entity.progress     = achievement.progress
            entity.total        = achievement.total
            entity.isCompleted  = achievement.isCompleted
            entity.completedDate = achievement.completedDate
        }
        PersistenceController.shared.save()
    }

    // MARK: Stats

    func totalWorkoutsCount() -> Int {
        let request = CDWorkoutSession.fetchRequest()
        return (try? context.count(for: request)) ?? 0
    }

    func totalCaloriesBurned() -> Double {
        let request = CDWorkoutSession.fetchRequest()
        guard let results = try? context.fetch(request) else { return 0 }
        return results.reduce(0) { $0 + $1.totalCalories }
    }

    func averageHeartRate(days: Int = 30) -> Double {
        let from = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let workouts = fetchWorkouts(from: from, to: Date())
        guard !workouts.isEmpty else { return 0 }
        return workouts.map { $0.averageHeartRate }.reduce(0, +) / Double(workouts.count)
    }

    // MARK: Private Mapping

    private func mapToSession(_ entity: CDWorkoutSession) -> WorkoutSession {
        var session = WorkoutSession(id: entity.id ?? UUID(),
                                     startDate: entity.startDate ?? Date(),
                                     phase: WorkoutPhase(rawValue: entity.phase ?? "") ?? .warmup)
        session.endDate          = entity.endDate
        session.duration         = entity.duration
        session.averageHeartRate = entity.averageHR
        session.maxHeartRate     = entity.maxHR
        session.minHeartRate     = entity.minHR
        session.totalCalories    = entity.totalCalories
        session.averageHRV       = entity.averageHRV
        session.peakLactate      = entity.peakLactate

        let roundsRequest = CDRoundData.fetchRequest()
        roundsRequest.predicate = NSPredicate(format: "workout == %@", entity)
        roundsRequest.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        if let rounds = try? context.fetch(roundsRequest) {
            session.rounds = rounds.map {
                var r = RoundData(number: Int($0.number))
                r.duration          = $0.duration
                r.averageHeartRate  = $0.averageHR
                r.maxHeartRate      = $0.maxHR
                r.peakLactate       = $0.peakLactate
                r.calories          = $0.calories
                r.startDate         = $0.startDate ?? Date()
                r.endDate           = $0.endDate
                return r
            }
        }
        return session
    }

    private func defaultAchievements() -> [Achievement] {
        [
            Achievement(title: "Первые шаги",    description: "Выполните 5 тренировок",         icon: "figure.walk",   total: 5),
            Achievement(title: "Мастер комбо",   description: "Выполните 10 раундов",            icon: "bolt.fill",     total: 10),
            Achievement(title: "Выносливость",   description: "Тренируйтесь суммарно 5 часов",   icon: "heart.fill",    total: 18000),
            Achievement(title: "Жиросжигатель",  description: "Сожгите 5000 ккал",               icon: "flame.fill",    total: 5000),
            Achievement(title: "Ночной боец",    description: "Отследите 7 ночей сна подряд",    icon: "moon.fill",     total: 7),
            Achievement(title: "Пульс чемпиона", description: "Достигните 95% от макс. ЧСС",    icon: "waveform.path", total: 1),
        ]
    }
}
