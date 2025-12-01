import Foundation

extension Weekday {
    static let uiOrder: [Weekday] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]
    
    var ruFull: String {
        switch self {
        case .monday:    NSLocalizedString("weekday_full_monday", comment: "")
        case .tuesday:   NSLocalizedString("weekday_full_tuesday", comment: "")
        case .wednesday: NSLocalizedString("weekday_full_wednesday", comment: "")
        case .thursday:  NSLocalizedString("weekday_full_thursday", comment: "")
        case .friday:    NSLocalizedString("weekday_full_friday", comment: "")
        case .saturday:  NSLocalizedString("weekday_full_saturday", comment: "")
        case .sunday:    NSLocalizedString("weekday_full_sunday", comment: "")
        }
    }
    
    var ruShort: String {
        switch self {
        case .monday:    NSLocalizedString("weekday_short_monday", comment: "")
        case .tuesday:   NSLocalizedString("weekday_short_tuesday", comment: "")
        case .wednesday: NSLocalizedString("weekday_short_wednesday", comment: "")
        case .thursday:  NSLocalizedString("weekday_short_thursday", comment: "")
        case .friday:    NSLocalizedString("weekday_short_friday", comment: "")
        case .saturday:  NSLocalizedString("weekday_short_saturday", comment: "")
        case .sunday:    NSLocalizedString("weekday_short_sunday", comment: "")
        }
    }
}

extension Collection where Element == Weekday {
    var ruListDescription: String {
        if count == 7 {
            return NSLocalizedString("schedule_every_day", comment: "")
        } else if isEmpty {
            return NSLocalizedString("schedule_not_set", comment: "")
        } else {
            let set = Set(self)
            return Weekday.uiOrder
                .filter { set.contains($0) }
                .map { $0.ruShort }
                .joined(separator: ", ")
        }
    }
}
