import Foundation
import CoreData
import UIKit

protocol TrackerStoreObserver: AnyObject {
    func storeWillChangeContent()
    func storeDidChangeSection(at sectionIndex: Int, for type: NSFetchedResultsChangeType)
    func storeDidChangeItem(at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    func storeDidChangeContent()
}

final class TrackerStore: NSObject, NSFetchedResultsControllerDelegate {
    
    weak var observer: TrackerStoreObserver?
    
    private let context: NSManagedObjectContext
    private let categoryStore: TrackerCategoryStore
    private var frc: NSFetchedResultsController<TrackerCoreData>!
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext,
         categoryStore: TrackerCategoryStore = TrackerCategoryStore()) {
        self.context = context
        self.categoryStore = categoryStore
        super.init()
        configureFRC()
    }
    
    private func configureFRC() {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "category.title", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))),
            NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))
        ]
        frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: "category.title",
            cacheName: nil
        )
        frc.delegate = self
    }
    
    func performFetch() throws { try frc.performFetch() }
    
    func numberOfSections() -> Int { frc.sections?.count ?? 0 }
    func numberOfItems(in section: Int) -> Int { frc.sections?[section].numberOfObjects ?? 0 }
    func titleForSection(_ section: Int) -> String { frc.sections?[section].name ?? "" }
    func object(at indexPath: IndexPath) -> TrackerCoreData { frc.object(at: indexPath) }
    
    func objects(inSection section: Int) -> [TrackerCoreData] {
        guard let sectionInfo = frc.sections?[section],
              let objs = sectionInfo.objects as? [TrackerCoreData] else { return [] }
        return objs
    }
    
    func mapToModel(_ obj: TrackerCoreData) -> Tracker {
        let id = obj.id ?? UUID()
        let name = obj.name ?? ""
        let colorHex = obj.colorHex ?? "#000000"
        let color = UIColor.hex(colorHex, fallback: .black)
        let emoji = obj.emoji ?? "🙂"
        
        var scheduleSet: Set<Weekday>? = nil
        if let arr = obj.schedule as? [NSNumber] {
            scheduleSet = Set(arr.compactMap { Weekday(rawValue: $0.intValue) })
        }
        return Tracker(id: id, name: name, color: color, emoji: emoji, schedule: scheduleSet)
    }
    
    func upsert(_ model: Tracker, in categoryTitle: String) throws {
        let fetch: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetch.predicate = NSPredicate(format: "id == %@", model.id as CVarArg)
        fetch.fetchLimit = 1
        let obj = try context.fetch(fetch).first ?? TrackerCoreData(context: context)
        
        obj.id = model.id
        obj.name = model.name
        obj.colorHex = model.color.toHexString() ?? "#000000"
        obj.emoji = model.emoji
        if let schedule = model.schedule {
            obj.schedule = schedule.map { NSNumber(value: $0.rawValue) } as NSArray
        } else {
            obj.schedule = nil
        }
        
        let category = try categoryStore.upsertCategory(with: categoryTitle)
        obj.category = category
        
        try saveIfNeeded()
    }
    
    func delete(id: UUID) throws {
        let fetch: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let obj = try context.fetch(fetch).first {
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

private extension UIColor {
    func toHexString() -> String? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let ri = Int(round(r * 255)), gi = Int(round(g * 255)), bi = Int(round(b * 255))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
