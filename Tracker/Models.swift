import Foundation
import UIKit

enum Weekday: Int, CaseIterable, Hashable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}

struct Tracker: Hashable {
    let id: UUID
    let name: String
    let color: UIColor
    let emoji: String
    let schedule: Set<Weekday>?
    
    init(id: UUID = UUID(),
         name: String,
         color: UIColor,
         emoji: String,
         schedule: Set<Weekday>? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.emoji = emoji
        self.schedule = schedule
    }
}

struct TrackerCategory: Hashable {
    let title: String
    let trackers: [Tracker]
}

struct TrackerRecord: Hashable {
    let trackerId: UUID
    let date: Date
    
    init(trackerId: UUID, date: Date) {
        self.trackerId = trackerId
        self.date = Calendar.current.startOfDay(for: date)
    }
}

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    
    func isSameDay(as other: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, inSameDayAs: other)
    }
}
