import UIKit
import CoreData

protocol TrackerStoreObserver: AnyObject {
    func storeDidUpdate(_ store: TrackerStore)
}

final class TrackerStore: NSObject {
    
    weak var observer: TrackerStoreObserver?
    
    private let context: NSManagedObjectContext
    private let fetchedResultsController: NSFetchedResultsController<TrackerCoreData>
    
    override init() {
        let context = CoreDataStack.shared.viewContext
        self.context = context
        
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        
        let categorySort = NSSortDescriptor(
            key: "category.title",
            ascending: true,
            selector: #selector(NSString.localizedCaseInsensitiveCompare)
        )
        let nameSort = NSSortDescriptor(
            key: "name",
            ascending: true,
            selector: #selector(NSString.localizedCaseInsensitiveCompare)
        )
        request.sortDescriptors = [categorySort, nameSort]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        super.init()
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("❌ performFetch error:", error)
        }
    }
    
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("❌ performFetch error:", error)
        }
    }
    
    func numberOfSections() -> Int {
        fetchedResultsController.sections?.count ?? 0
    }
    
    func numberOfObjects(in section: Int) -> Int {
        fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func object(at indexPath: IndexPath) -> Tracker {
        let core = fetchedResultsController.object(at: indexPath)
        return mapToModel(core)
    }
    
    func categoryTitle(for indexPath: IndexPath) -> String {
        let core = fetchedResultsController.object(at: indexPath)
        return core.category?.title ?? ""
    }
    
    
    func upsert(_ tracker: Tracker, in category: TrackerCategory) {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        let core = (try? context.fetch(request).first) ?? TrackerCoreData(context: context)
        
        core.id = tracker.id
        core.name = tracker.name
        core.emoji = tracker.emoji
        core.colorHex = tracker.color.toHexString()
        
        if let schedule = tracker.schedule {
            let raw = schedule.map { NSNumber(value: $0.rawValue) }
            core.schedule = raw as NSArray
        } else {
            core.schedule = nil
        }
        
        let catRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        catRequest.fetchLimit = 1
        catRequest.predicate = NSPredicate(format: "title == %@", category.title)
        
        if let catCore = try? context.fetch(catRequest).first {
            core.category = catCore
        }
        
        saveContext()
    }
    
    func delete(tracker: Tracker) {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        if let core = try? context.fetch(request).first {
            context.delete(core)
            saveContext()
        }
    }
    
    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("❌ context save error:", error)
        }
    }
    
    private func mapToModel(_ core: TrackerCoreData) -> Tracker {
        let color = UIColor(hex: core.colorHex ?? "#FFFFFF")
        let scheduleArray = core.schedule as? [Int]
        let schedule: Set<Weekday>? = scheduleArray.map {
            Set($0.compactMap { Weekday(rawValue: $0) })
        }
        
        return Tracker(
            id: core.id ?? UUID(),
            name: core.name ?? "",
            color: color,
            emoji: core.emoji ?? "🙂",
            schedule: schedule
        )
    }
}

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        observer?.storeDidUpdate(self)
    }
}
