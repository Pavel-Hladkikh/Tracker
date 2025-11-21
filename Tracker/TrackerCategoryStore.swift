import CoreData

enum TrackerCategoryStoreError: Error {
    case notFound
}

final class TrackerCategoryStore {
    private let context = CoreDataStack.shared.context
    
    func addCategory(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        guard !isCategoryExists(withTitle: trimmed) else { return }
        
        let cd = TrackerCategoryCoreData(context: context)
        cd.id = UUID()
        cd.title = trimmed
        cd.createdAt = Date()
        cd.isSelected = false
        
        saveContext()
    }
    
    func fetchAllCategoriesWithoutFetchingIncludedTrackers() -> [TrackerCategory] {
        let req: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        do {
            let items = try context.fetch(req)
            return items.map {
                TrackerCategory(id: $0.id ?? UUID(),
                                title: $0.title ?? "",
                                trackers: [])
            }
        } catch {
            print("Ошибка при получении категорий: \(error)")
            return []
        }
    }
    
    func updateCategory(id: UUID, newTitle: String) throws {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let req: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        guard let obj = try context.fetch(req).first else {
            throw TrackerCategoryStoreError.notFound
        }
        
        obj.title = trimmed
        
        if let trackers = obj.trackers as? Set<TrackerCoreData> {
            for tracker in trackers {
                tracker.category = obj
            }
        }
        
        try context.save()
    }
    
    func deleteCategory(id: UUID) throws {
        let req: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        guard let obj = try context.fetch(req).first else {
            throw TrackerCategoryStoreError.notFound
        }
        
        if let trackers = obj.trackers as? Set<TrackerCoreData> {
            trackers.forEach { context.delete($0) }
        }
        
        context.delete(obj)
        try context.save()
    }
    
    private func isCategoryExists(withTitle title: String) -> Bool {
        let req: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        req.predicate = NSPredicate(format: "title == %@", title)
        let count = (try? context.count(for: req)) ?? 0
        return count > 0
    }
    
    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Ошибка сохранения контекста категорий: \(error)")
        }
    }
}
