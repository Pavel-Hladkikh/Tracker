import Foundation

enum TrackerFilter: CaseIterable, Equatable {
    case all
    case today
    case completed
    case incomplete
    
    var titleKey: String {
        switch self {
        case .all:        return "filters_all"
        case .today:      return "filters_today"
        case .completed:  return "filters_done"
        case .incomplete: return "filters_undone"
        }
    }
    
    var showsCheckmark: Bool {
        switch self {
        case .all, .today: return false
        default: return true
        }
    }
}
