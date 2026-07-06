import XCTest
@testable import MovieQuiz

final class ArrayTests: XCTestCase {
    func testSafeSubscriptReturnsElementForExistingIndex() {
        let values = ["first", "second", "third"]

        XCTAssertEqual(values[safe: 1], "second")
    }

    func testSafeSubscriptReturnsNilForMissingIndex() {
        let values = ["first", "second", "third"]

        XCTAssertNil(values[safe: 3])
    }
}
