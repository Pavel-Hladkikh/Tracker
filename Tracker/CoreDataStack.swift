import CoreData

final class CoreDataStack {
    
    static let shared = CoreDataStack()
    
    private(set) var persistentContainer: NSPersistentContainer
    
    
    var viewContext: NSManagedObjectContext { persistentContainer.viewContext }
    
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        return context
    }()
    
    private init() {
        let container = NSPersistentContainer(name: "Model")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved Core Data error while loading stores: \(error)")
            }
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
        
        self.persistentContainer = container
    }
    
    func saveContext(_ context: NSManagedObjectContext? = nil) {
        let contextToSave = context ?? viewContext
        guard contextToSave.hasChanges else { return }
        do {
            try contextToSave.save()
        } catch {
            contextToSave.rollback()
            assertionFailure("Core Data save failed: \(error)")
        }
    }
}
