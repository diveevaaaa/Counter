import Foundation

struct StatisticsSummary {
    let bestPeriod: Int
    let idealDays: Int
    let completed: Int
    let average: Int

    var hasData: Bool {
        completed > 0 || bestPeriod > 0 || idealDays > 0 || average > 0
    }
}

enum StatisticsCalculator {
    static func summary(
        categories: [TrackerCategory],
        records: [TrackerRecord],
        calendar: Calendar = .current,
        today: Date = Date()
    ) -> StatisticsSummary {
        let trackers = categories.flatMap(\.trackers)
        let completed = records.count
        let bestPeriod = trackers
            .map { longestStreak(records: records, trackerId: $0.id, calendar: calendar) }
            .max() ?? 0
        let idealDays = idealDayCount(
            trackers: trackers,
            records: records,
            calendar: calendar,
            today: today
        )
        let activeDays = Set(records.map { calendar.startOfDay(for: $0.date) }).count
        let average = activeDays == 0 ? 0 : completed / activeDays
        return StatisticsSummary(
            bestPeriod: bestPeriod,
            idealDays: idealDays,
            completed: completed,
            average: average
        )
    }

    private static func longestStreak(records: [TrackerRecord], trackerId: UUID, calendar: Calendar) -> Int {
        let days = Set(
            records
                .filter { $0.trackerId == trackerId }
                .map { calendar.startOfDay(for: $0.date) }
        ).sorted()
        guard !days.isEmpty else { return 0 }
        var best = 1
        var current = 1
        for index in 1..<days.count {
            let distance = calendar.dateComponents([.day], from: days[index - 1], to: days[index]).day ?? 0
            if distance == 1 {
                current += 1
                best = max(best, current)
            } else if distance > 1 {
                current = 1
            }
        }
        return best
    }

    private static func idealDayCount(
        trackers: [Tracker],
        records: [TrackerRecord],
        calendar: Calendar,
        today: Date
    ) -> Int {
        guard let firstRecord = records.map(\.date).min() else { return 0 }
        var day = calendar.startOfDay(for: firstRecord)
        let end = calendar.startOfDay(for: today)
        var count = 0
        while day <= end {
            let scheduled = trackers.filter { $0.isScheduled(on: day, calendar: calendar) }
            if !scheduled.isEmpty {
                let finished = scheduled.allSatisfy { tracker in
                    records.contains { record in
                        record.trackerId == tracker.id && calendar.isDate(record.date, inSameDayAs: day)
                    }
                }
                if finished {
                    count += 1
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return count
    }
}
