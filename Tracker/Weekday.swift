import Foundation

extension Weekday {
    static let uiOrder: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    var ruFull: String {
        switch self {
        case .monday: return "Понедельник"
        case .tuesday: return "Вторник"
        case .wednesday: return "Среда"
        case .thursday: return "Четверг"
        case .friday: return "Пятница"
        case .saturday: return "Суббота"
        case .sunday: return "Воскресенье"
        }
    }

    var ruShort: String {
        switch self {
        case .monday: return "Пн"
        case .tuesday: return "Вт"
        case .wednesday: return "Ср"
        case .thursday: return "Чт"
        case .friday: return "Пт"
        case .saturday: return "Сб"
        case .sunday: return "Вс"
        }
    }
}

extension Collection where Element == Weekday {
    var ruListDescription: String {
        if count == 7 { return "Каждый день" }
        if isEmpty { return "Не задано" }
        let set = Set(self)
        return Weekday.uiOrder.filter { set.contains($0) }
            .map { $0.ruShort }
            .joined(separator: ", ")
    }
}
