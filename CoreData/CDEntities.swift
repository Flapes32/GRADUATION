import CoreData
import Foundation

// MARK: - CDWorkoutSession

@objc(CDWorkoutSession)
public class CDWorkoutSession: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var duration: Double
    @NSManaged public var averageHR: Double
    @NSManaged public var maxHR: Double
    @NSManaged public var minHR: Double
    @NSManaged public var totalCalories: Double
    @NSManaged public var averageHRV: Double
    @NSManaged public var peakLactate: Double
    @NSManaged public var phase: String?
    @NSManaged public var rounds: NSSet?
}

extension CDWorkoutSession {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDWorkoutSession> {
        return NSFetchRequest<CDWorkoutSession>(entityName: "CDWorkoutSession")
    }
}

// MARK: - CDRoundData

@objc(CDRoundData)
public class CDRoundData: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var number: Int16
    @NSManaged public var duration: Double
    @NSManaged public var averageHR: Double
    @NSManaged public var maxHR: Double
    @NSManaged public var peakLactate: Double
    @NSManaged public var calories: Double
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var workout: CDWorkoutSession?
}

extension CDRoundData {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDRoundData> {
        return NSFetchRequest<CDRoundData>(entityName: "CDRoundData")
    }
}

// MARK: - CDHeartRateRecord

@objc(CDHeartRateRecord)
public class CDHeartRateRecord: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var value: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var workoutSessionId: UUID?
}

extension CDHeartRateRecord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDHeartRateRecord> {
        return NSFetchRequest<CDHeartRateRecord>(entityName: "CDHeartRateRecord")
    }
}

// MARK: - CDSleepData

@objc(CDSleepData)
public class CDSleepData: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var durationHours: Double
    @NSManaged public var deepSleepPercent: Double
    @NSManaged public var remSleepPercent: Double
    @NSManaged public var awakePercent: Double
    @NSManaged public var qualityScore: Double
}

extension CDSleepData {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSleepData> {
        return NSFetchRequest<CDSleepData>(entityName: "CDSleepData")
    }
}

// MARK: - CDAchievement

@objc(CDAchievement)
public class CDAchievement: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var desc: String?
    @NSManaged public var icon: String?
    @NSManaged public var progress: Double
    @NSManaged public var total: Double
    @NSManaged public var isCompleted: Bool
    @NSManaged public var completedDate: Date?
}

extension CDAchievement {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAchievement> {
        return NSFetchRequest<CDAchievement>(entityName: "CDAchievement")
    }
}
