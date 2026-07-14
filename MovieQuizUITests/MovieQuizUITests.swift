import XCTest

final class MovieQuizUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testYesButtonChangesQuestionCounter() {
        waitForReadyQuestion("1/10")

        app.buttons["yesButton"].tap()

        waitForReadyQuestion("2/10")
    }

    func testNoButtonChangesQuestionCounter() {
        waitForReadyQuestion("1/10")

        app.buttons["noButton"].tap()

        waitForReadyQuestion("2/10")
    }

    func testAlertAppearsAtEndOfRound() {
        finishRound()

        let alert = app.alerts["Этот раунд окончен!"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        XCTAssertTrue(alert.buttons["Сыграть ещё раз"].exists)
    }

    func testAlertDismissesAndCounterResets() {
        finishRound()

        let alert = app.alerts["Этот раунд окончен!"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.buttons["Сыграть ещё раз"].tap()

        XCTAssertTrue(waitForAlertToDisappear(alert))
        waitForReadyQuestion("1/10")
    }

    private func finishRound() {
        waitForReadyQuestion("1/10")

        for questionNumber in 2...10 {
            app.buttons["yesButton"].tap()
            waitForReadyQuestion("\(questionNumber)/10")
        }

        app.buttons["yesButton"].tap()
    }

    private func waitForReadyQuestion(_ value: String) {
        waitForQuestionCounter(value)
        XCTAssertTrue(app.buttons["yesButton"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["yesButton"].isEnabled)
    }

    private func waitForQuestionCounter(_ value: String) {
        let predicate = NSPredicate(format: "label == %@", value)
        let expectation = expectation(
            for: predicate,
            evaluatedWith: app.staticTexts["questionCounter"]
        )

        wait(for: [expectation], timeout: 3)
    }

    private func waitForAlertToDisappear(_ alert: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = expectation(for: predicate, evaluatedWith: alert)
        let result = XCTWaiter.wait(for: [expectation], timeout: 3)
        return result == .completed
    }
}
