import SnapshotTesting
import UIKit
import XCTest
@testable import Tracker

final class TrackersViewControllerSnapshotTests: XCTestCase {
    func testMainScreenLight() {
        assertSnapshot(
            of: makeController(),
            as: .image(on: .iPhone13, traits: .init(userInterfaceStyle: .light))
        )
    }

    func testMainScreenDark() {
        assertSnapshot(
            of: makeController(),
            as: .image(on: .iPhone13, traits: .init(userInterfaceStyle: .dark))
        )
    }

    private func makeController() -> UINavigationController {
        let controller = TrackersViewController(usesPersistentStore: false)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15)) ?? Date()
        let tracker = Tracker(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
            name: "Поливать растения",
            color: TrackerPalette.color(at: 0),
            emoji: "🌺",
            schedule: .habit(Set(Weekday.allCases))
        )
        controller.currentDate = date
        controller.categories = [TrackerCategory(title: "Важное", trackers: [tracker])]
        controller.completedTrackers = [TrackerRecord(trackerId: tracker.id, date: date)]

        let navigation = UINavigationController(rootViewController: controller)
        navigation.navigationBar.applyTrackerAppearance(usesCompactTitle: false)
        navigation.navigationBar.prefersLargeTitles = true
        return navigation
    }
}
