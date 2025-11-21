import Foundation
import UIKit

final class TrackerStorage {
    static let shared = TrackerStorage()
    private init() {}
    
    private let filename = "tracker_state.json"
    
    private var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(filename)
    }
    
    private func colorForUUID(_ id: UUID) -> UIColor {
        let s = id.uuidString.unicodeScalars.map { UInt32($0.value) }
        let sum = s.reduce(0, +)
        let hue = CGFloat(sum % 360) / 360.0
        return UIColor(hue: hue, saturation: 0.62, brightness: 0.86, alpha: 1)
    }
    
    
    func load() -> (categories: [TrackerCategory], completed: Set<TrackerRecord>)? {
        guard let fileURL = fileURL,
              let data = try? Data(contentsOf: fileURL),
              let dto = try? JSONDecoder().decode(AppStateDTO.self, from: data) else {
            return nil
        }
        
        let categories = dto.categories.map { c -> TrackerCategory in
            let trackers = c.trackers.map { t -> Tracker in
                Tracker(
                    id: t.id,
                    name: t.name,
                    color: colorForUUID(t.id),
                    emoji: t.emoji,
                    schedule: nil
                )
            }
            return TrackerCategory(id: c.id, title: c.title, trackers: trackers)
        }
        
        let completedArray = dto.completed.map { TrackerRecord(trackerId: $0.trackerId, date: $0.date) }
        return (categories, Set(completedArray))
    }
    
    func save(categories: [TrackerCategory], completed: Set<TrackerRecord>) throws {
        guard let fileURL = fileURL else { throw StorageError.fileURLUnavailable }
        
        let categoryDTOs: [CategoryDTO] = categories.map { cat in
            let trackerDTOs = cat.trackers.map { tr in
                TrackerDTO(id: tr.id, name: tr.name, emoji: tr.emoji)
            }
            return CategoryDTO(id: cat.id, title: cat.title, trackers: trackerDTOs)
        }
        
        let completedDTOs = completed.map { rec in
            CompletedDTO(trackerId: rec.trackerId, date: rec.date)
        }
        
        let app = AppStateDTO(categories: categoryDTOs, completed: Array(completedDTOs))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(app)
        try data.write(to: fileURL, options: .atomic)
    }
    
    func clear() throws {
        guard let fileURL = fileURL else { return }
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    private struct AppStateDTO: Codable {
        var categories: [CategoryDTO]
        var completed: [CompletedDTO]
    }
    
    private struct CategoryDTO: Codable {
        var id: UUID
        var title: String
        var trackers: [TrackerDTO]
    }
    
    private struct TrackerDTO: Codable {
        var id: UUID
        var name: String
        var emoji: String
    }
    
    private struct CompletedDTO: Codable {
        var trackerId: UUID
        var date: Date
    }
    
    enum StorageError: Error {
        case fileURLUnavailable
    }
}
