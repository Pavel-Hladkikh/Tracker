import Foundation
import CoreData

protocol TrackerRecordStoreObserver: AnyObject {
    func storeWillChangeContent()
    func storeDidChangeSection(at sectionIndex: Int, for type: StoreChangeType)
    func storeDidChangeItem(at indexPath: IndexPath?, for type: StoreChangeType, newIndexPath: IndexPath?)
    func storeDidChangeContent()
}

final class TrackerRecordStore: NSObject, NSFetchedResultsControllerDelegate {

    weak var observer: TrackerRecordStoreObserver?

    private let context: NSManagedObjectContext
    private var frc: NSFetchedResultsController<TrackerRecordCoreData>!

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
        super.init()
        configureFRC()
    }

    private func configureFRC(predicate: NSPredicate? = nil) {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: context,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        frc.delegate = self
    }

    func performFetch() throws { try frc.performFetch() }

    func numberOfSections() -> Int { frc.sections?.count ?? 0 }
    func numberOfItems(in section: Int) -> Int { frc.sections?[section].numberOfObjects ?? 0 }
    func object(at indexPath: IndexPath) -> TrackerRecordCoreData { frc.object(at: indexPath) }

    func mapToModel(_ obj: TrackerRecordCoreData) -> TrackerRecord? {
        guard let trackerId = obj.tracker?.id, let date = obj.date else { return nil }
        return TrackerRecord(trackerId: trackerId, date: date)
    }

    func add(_ record: TrackerRecord) throws {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", record.trackerId as CVarArg)
        request.fetchLimit = 1
        guard let tracker = try context.fetch(request).first else { return }

        if try fetchRecordObject(trackerId: record.trackerId, date: record.date) != nil { return }

        let obj = TrackerRecordCoreData(context: context)
        obj.date = record.date.startOfDay
        obj.tracker = tracker
        try saveIfNeeded()
    }

    func remove(_ record: TrackerRecord) throws {
        if let obj = try fetchRecordObject(trackerId: record.trackerId, date: record.date) {
            context.delete(obj)
            try saveIfNeeded()
        }
    }

    func isCompleted(trackerId: UUID, on date: Date) throws -> Bool {
        return try fetchRecordObject(trackerId: trackerId, date: date) != nil
    }

    func completionCount(trackerId: UUID) throws -> Int {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "tracker.id == %@", trackerId as CVarArg)
        return try context.count(for: request)
    }

    func removeAll(for trackerId: UUID) throws {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "tracker.id == %@", trackerId as CVarArg)
        let rows = try context.fetch(request)
        rows.forEach { context.delete($0) }
        try saveIfNeeded()
    }

    private func fetchRecordObject(trackerId: UUID, date: Date) throws -> TrackerRecordCoreData? {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        let start = date.startOfDay as NSDate
        let end = Calendar.current.date(byAdding: .day, value: 1, to: date.startOfDay)! as NSDate
        request.predicate = NSPredicate(format: "tracker.id == %@ AND (date >= %@) AND (date < %@)",
                                        trackerId as CVarArg, start, end)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func saveIfNeeded() throws {
        if context.hasChanges { try context.save() }
    }

    private func mapChange(_ type: NSFetchedResultsChangeType) -> StoreChangeType {
        switch type {
        case .insert: return .insert
        case .delete: return .delete
        case .move:   return .move
        case .update: return .update
        @unknown default: return .update
        }
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        observer?.storeWillChangeContent()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        observer?.storeDidChangeSection(at: sectionIndex, for: mapChange(type))
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        observer?.storeDidChangeItem(at: indexPath, for: mapChange(type), newIndexPath: newIndexPath)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        observer?.storeDidChangeContent()
    }
}
