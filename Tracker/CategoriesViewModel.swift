import Foundation

extension Notification.Name {
    static let categoryDidUpdate = Notification.Name("categoryDidUpdate")
}

final class CategoriesViewModel {
    
    var onCategoriesUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    var onCategoryPicked: ((TrackerCategory) -> Void)?
    
    private let store = TrackerCategoryStore()
    
    private(set) var categories: [TrackerCategory] = [] {
        didSet { onCategoriesUpdated?() }
    }
    
    private(set) var selectedCategoryId: UUID?
    private let lastSelectedCategoryKey = "lastSelectedCategoryId"
    
    init(preselectedCategoryTitle: String? = nil) {
        reloadCategoriesInternal()
        
        if let title = preselectedCategoryTitle,
           let match = categories.first(where: { $0.title == title }) {
            selectedCategoryId = match.id
            saveLastSelectedCategoryId(match.id)
        } else if let storedId = loadLastSelectedCategoryId(),
                  categories.contains(where: { $0.id == storedId }) {
            selectedCategoryId = storedId
        }
    }
    
    var countOfCategories: Int { categories.count }
    
    func category(at index: Int) -> TrackerCategory? {
        guard categories.indices.contains(index) else { return nil }
        return categories[index]
    }
    
    func title(at index: Int) -> String {
        category(at: index)?.title ?? ""
    }
    
    func isSelectedCategory(at index: Int) -> Bool {
        guard let id = category(at: index)?.id,
              let selectedId = selectedCategoryId else { return false }
        return id == selectedId
    }
    
    func userSelectedCategory(at index: Int) {
        guard let cat = category(at: index) else { return }
        selectedCategoryId = cat.id
        saveLastSelectedCategoryId(cat.id)
        onCategoryPicked?(cat)
        onCategoriesUpdated?()
    }
    
    func addCategory(title: String) {
        store.addCategory(title: title)
        reloadCategoriesInternal()
        if let new = categories.first(where: { $0.title == title }) {
            selectedCategoryId = new.id
            saveLastSelectedCategoryId(new.id)
            onCategoriesUpdated?()
        }
        NotificationCenter.default.post(name: .categoryDidUpdate, object: nil)
    }
    
    func renameCategory(at index: Int, newTitle: String) {
        guard let cat = category(at: index) else { return }
        do {
            try store.updateCategory(id: cat.id, newTitle: newTitle)
            reloadCategoriesInternal()
            NotificationCenter.default.post(name: .categoryDidUpdate, object: nil)
        } catch {
            onError?("Не удалось переименовать категорию")
        }
    }
    
    func deleteCategory(at index: Int) {
        guard let cat = category(at: index) else { return }
        do {
            try store.deleteCategory(id: cat.id)
            if cat.id == selectedCategoryId {
                selectedCategoryId = nil
                saveLastSelectedCategoryId(nil)
            }
            reloadCategoriesInternal()
            NotificationCenter.default.post(name: .categoryDidUpdate, object: nil)
        } catch {
            onError?("Не удалось удалить категорию")
        }
    }
    
    func reloadCategories() {
        reloadCategoriesInternal()
    }
    
    private func reloadCategoriesInternal() {
        categories = store.fetchAllCategoriesWithoutFetchingIncludedTrackers()
        if let selectedId = selectedCategoryId,
           !categories.contains(where: { $0.id == selectedId }) {
            selectedCategoryId = nil
            saveLastSelectedCategoryId(nil)
        }
    }
    
    private func saveLastSelectedCategoryId(_ id: UUID?) {
        let defaults = UserDefaults.standard
        if let id = id {
            defaults.set(id.uuidString, forKey: lastSelectedCategoryKey)
        } else {
            defaults.removeObject(forKey: lastSelectedCategoryKey)
        }
    }
    
    private func loadLastSelectedCategoryId() -> UUID? {
        let defaults = UserDefaults.standard
        guard let string = defaults.string(forKey: lastSelectedCategoryKey) else {
            return nil
        }
        return UUID(uuidString: string)
    }
}
