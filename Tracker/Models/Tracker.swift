import UIKit

enum TrackerSchedule {
    case habit(Set<Weekday>)
    case irregular
}

struct Tracker {
    let id: UUID
    let name: String
    let color: UIColor
    let emoji: String
    let schedule: TrackerSchedule
}

extension TrackerSchedule {
    var storedValue: String {
        switch self {
        case .irregular:
            return "irregular"
        case .habit(let days):
            return days.map { String($0.rawValue) }.sorted().joined(separator: ",")
        }
    }

    init(storedValue: String) {
        if storedValue == "irregular" {
            self = .irregular
            return
        }
        let days = Set(
            storedValue
                .split(separator: ",")
                .compactMap { Int($0) }
                .compactMap(Weekday.init(rawValue:))
        )
        self = .habit(days)
    }
}

extension Tracker {
    func isScheduled(on date: Date, calendar: Calendar) -> Bool {
        switch schedule {
        case .habit(let days):
            let weekdayValue = calendar.component(.weekday, from: date)
            guard let weekday = Weekday(rawValue: weekdayValue) else { return false }
            return days.contains(weekday)
        case .irregular:
            return true
        }
    }
}
