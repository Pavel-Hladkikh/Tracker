import CoreData

final class TrackerRecordStore {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }
    
    func addRecord(for trackerId: UUID, on date: Date) {
        guard let trackerCore = fetchTrackerCore(by: trackerId) else {
            print("TrackerCoreData not found for id \(trackerId)")
            return
        }
        
        if isTrackerCompleted(trackerId, on: date) { return }
        
        let record = TrackerRecordCoreData(context: context)
        record.date = date.startOfDay
        record.tracker = trackerCore
        saveContext()
    }
    
    func removeRecord(for trackerId: UUID, on date: Date) {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(
            format: "tracker.id == %@ AND date == %@",
            trackerId as CVarArg,
            date.startOfDay as CVarArg
        )
        
        if let record = try? context.fetch(request).first {
            context.delete(record)
            saveContext()
        }
    }
    
    func isTrackerCompleted(_ trackerId: UUID, on date: Date) -> Bool {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(
            format: "tracker.id == %@ AND date == %@",
            trackerId as CVarArg,
            date.startOfDay as CVarArg
        )
        let count = (try? context.count(for: request)) ?? 0
        return count > 0
    }
    
    func completedCount(for trackerId: UUID) -> Int {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(
            format: "tracker.id == %@",
            trackerId as CVarArg
        )
        let count = (try? context.count(for: request)) ?? 0
        return count
    }
    
    private func fetchTrackerCore(by id: UUID) -> TrackerCoreData? {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }
    
    private func saveContext() {
        if context.hasChanges {
            try? context.save()
        }
    }
}
