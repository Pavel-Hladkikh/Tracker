import Foundation
import CoreData

protocol TrackerCategoryStoreObserver: AnyObject {
    func storeWillChangeContent()
    func storeDidChangeSection(at sectionIndex: Int, for type: NSFetchedResultsChangeType)
    func storeDidChangeItem(at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    func storeDidChangeContent()
}

final class TrackerCategoryStore: NSObject, NSFetchedResultsControllerDelegate {
    
    weak var observer: TrackerCategoryStoreObserver?
    
    private let context: NSManagedObjectContext
    private var frc: NSFetchedResultsController<TrackerCategoryCoreData>!
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
        super.init()
        configureFRC()
    }
    
    private func configureFRC() {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))
        ]
        frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        frc.delegate = self
    }
    
    func performFetch() throws { try frc.performFetch() }
    
    func numberOfSections() -> Int { frc.sections?.count ?? 0 }
    func numberOfItems(in section: Int) -> Int { frc.sections?[section].numberOfObjects ?? 0 }
    func object(at indexPath: IndexPath) -> TrackerCategoryCoreData { frc.object(at: indexPath) }
    
    @discardableResult
    func upsertCategory(with title: String) throws -> TrackerCategoryCoreData {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", title)
        request.fetchLimit = 1
        let existing = try context.fetch(request).first
        if let obj = existing { return obj }
        
        let obj = TrackerCategoryCoreData(context: context)
        obj.title = title
        try saveIfNeeded()
        return obj
    }
    
    func deleteCategory(title: String) throws {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", title)
        if let obj = try context.fetch(request).first {
            context.delete(obj)
            try saveIfNeeded()
        }
    }
    
    func saveIfNeeded() throws {
        if context.hasChanges { try context.save() }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        observer?.storeWillChangeContent()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        observer?.storeDidChangeSection(at: sectionIndex, for: type)
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        observer?.storeDidChangeItem(at: indexPath, for: type, newIndexPath: newIndexPath)
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        observer?.storeDidChangeContent()
    }
}
