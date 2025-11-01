import Foundation

extension Weekday {
    static let uiOrder: [Weekday] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]
    
    var ruFull: String {
        switch self {
        case .monday: "Понедельник"
        case .tuesday: "Вторник"
        case .wednesday: "Среда"
        case .thursday: "Четверг"
        case .friday: "Пятница"
        case .saturday: "Суббота"
        case .sunday: "Воскресенье"
        }
    }
    
    var ruShort: String {
        switch self {
        case .monday: "Пн"
        case .tuesday: "Вт"
        case .wednesday: "Ср"
        case .thursday: "Чт"
        case .friday: "Пт"
        case .saturday: "Сб"
        case .sunday: "Вс"
        }
    }
}

extension Collection where Element == Weekday {
    var ruListDescription: String {
        if count == 7 {
            return "Каждый день"
        } else if isEmpty {
            return "Не задано"
        } else {
            let set = Set(self)
            return Weekday.uiOrder
                .filter { set.contains($0) }
                .map { $0.ruShort }
                .joined(separator: ", ")
        }
    }
}
