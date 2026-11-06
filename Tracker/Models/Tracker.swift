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
