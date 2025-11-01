import UIKit

private struct TrackerDTO: Codable {
    let id: UUID
    let name: String
    let colorHex: String
    let emoji: String
    let schedule: [Int]?
}

private struct TrackerCategoryDTO: Codable {
    let title: String
    let trackers: [TrackerDTO]
}

private struct TrackerRecordDTO: Codable {
    let trackerId: UUID
    let date: Date
}

private struct AppStateDTO: Codable {
    let categories: [TrackerCategoryDTO]
    let completed: [TrackerRecordDTO]
}

final class TrackerStorage {
    static let shared = TrackerStorage()
    private init() {}
    
    private let filename = "tracker_state.json"
    
    private var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(filename)
    }
    
    func load() -> (categories: [TrackerCategory], completed: Set<TrackerRecord>)? {
        guard
            let fileURL = fileURL,
            let data = try? Data(contentsOf: fileURL),
            let dto = try? JSONDecoder().decode(AppStateDTO.self, from: data)
        else {
            return nil
        }
        
        let categories = dto.categories.map { $0.toModel() }
        let completedArray = dto.completed.map {
            TrackerRecord(trackerId: $0.trackerId, date: $0.date)
        }
        return (categories, Set(completedArray))
    }
    
    func save(categories: [TrackerCategory], completed: Set<TrackerRecord>) {
        guard let fileURL = fileURL else { return }
        let dto = AppStateDTO(
            categories: categories.map { $0.toDTO() },
            completed: Array(completed).map {
                TrackerRecordDTO(trackerId: $0.trackerId, date: $0.date)
            }
        )
        do {
            let data = try JSONEncoder().encode(dto)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("TrackerStorage save error:", error)
        }
    }
}

private extension TrackerCategoryDTO {
    func toModel() -> TrackerCategory {
        TrackerCategory(title: title, trackers: trackers.map { $0.toModel() })
    }
}

private extension TrackerDTO {
    func toModel() -> Tracker {
        let color = UIColor.hex(colorHex, fallback: .black)
        let scheduleSet: Set<Weekday>? = schedule.map {
            Set($0.compactMap(Weekday.init(rawValue:)))
        }
        return Tracker(id: id, name: name, color: color, emoji: emoji, schedule: scheduleSet)
    }
}

private extension TrackerCategory {
    func toDTO() -> TrackerCategoryDTO {
        TrackerCategoryDTO(title: title, trackers: trackers.map { $0.toDTO() })
    }
}

private extension Tracker {
    func toDTO() -> TrackerDTO {
        TrackerDTO(
            id: id,
            name: name,
            colorHex: color.toHexString() ?? "#000000",
            emoji: emoji,
            schedule: schedule.map { $0.map { $0.rawValue } }
        )
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
