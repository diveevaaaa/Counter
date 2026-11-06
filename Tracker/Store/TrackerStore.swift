import UIKit

struct TrackerSnapshot {
    let categories: [TrackerCategory]
    let records: [TrackerRecord]
}

final class TrackerStore {
    private let url: URL

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        url = directory.appendingPathComponent("trackers.json")
    }

    func load() -> TrackerSnapshot {
        guard let data = try? Data(contentsOf: url),
              let stored = try? JSONDecoder().decode(StoredSnapshot.self, from: data) else {
            return TrackerSnapshot(categories: [], records: [])
        }
        let categories = stored.categories.map { category in
            TrackerCategory(
                title: category.title,
                trackers: category.trackers.map { tracker in
                    let schedule: TrackerSchedule = tracker.irregular
                        ? .irregular
                        : .habit(Set(tracker.weekdays.compactMap(Weekday.init(rawValue:))))
                    return Tracker(
                        id: tracker.id,
                        name: tracker.name,
                        color: UIColor(trackerHex: tracker.colorHex),
                        emoji: tracker.emoji,
                        schedule: schedule
                    )
                }
            )
        }
        let records = stored.records.map {
            TrackerRecord(trackerId: $0.trackerId, date: $0.date)
        }
        return TrackerSnapshot(categories: categories, records: records)
    }

    func save(categories: [TrackerCategory], records: [TrackerRecord]) {
        let stored = StoredSnapshot(
            categories: categories.map { category in
                StoredCategory(
                    title: category.title,
                    trackers: category.trackers.map { tracker in
                        let weekdays: [Int]
                        let irregular: Bool
                        switch tracker.schedule {
                        case .habit(let days):
                            irregular = false
                            weekdays = days.map(\.rawValue).sorted()
                        case .irregular:
                            irregular = true
                            weekdays = []
                        }
                        return StoredTracker(
                            id: tracker.id,
                            name: tracker.name,
                            emoji: tracker.emoji,
                            colorHex: tracker.color.trackerHex,
                            irregular: irregular,
                            weekdays: weekdays
                        )
                    }
                )
            },
            records: records.map { StoredRecord(trackerId: $0.trackerId, date: $0.date) }
        )
        guard let data = try? JSONEncoder().encode(stored) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

private struct StoredSnapshot: Codable {
    let categories: [StoredCategory]
    let records: [StoredRecord]
}

private struct StoredCategory: Codable {
    let title: String
    let trackers: [StoredTracker]
}

private struct StoredTracker: Codable {
    let id: UUID
    let name: String
    let emoji: String
    let colorHex: String
    let irregular: Bool
    let weekdays: [Int]
}

private struct StoredRecord: Codable {
    let trackerId: UUID
    let date: Date
}
