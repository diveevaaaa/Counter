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
    let isPinned: Bool

    init(
        id: UUID,
        name: String,
        color: UIColor,
        emoji: String,
        schedule: TrackerSchedule,
        isPinned: Bool = false
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.emoji = emoji
        self.schedule = schedule
        self.isPinned = isPinned
    }
}

extension TrackerSchedule {
    var storedValue: String {
        switch self {
        case .irregular:
            "irregular"
        case .habit(let days):
            days.map { String($0.rawValue) }.sorted().joined(separator: ",")
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
