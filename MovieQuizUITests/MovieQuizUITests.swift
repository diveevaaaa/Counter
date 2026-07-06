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
        waitForQuestionCounter("1/10")

        app.buttons["yesButton"].tap()

        waitForQuestionCounter("2/10")
    }

    func testNoButtonChangesQuestionCounter() {
        waitForQuestionCounter("1/10")

        app.buttons["noButton"].tap()

        waitForQuestionCounter("2/10")
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

        XCTAssertFalse(alert.exists)
        waitForQuestionCounter("1/10")
    }

    private func finishRound() {
        waitForQuestionCounter("1/10")

        for questionNumber in 2...10 {
            app.buttons["yesButton"].tap()
            waitForQuestionCounter("\(questionNumber)/10")
        }

        app.buttons["yesButton"].tap()
    }

    private func waitForQuestionCounter(_ value: String) {
        let predicate = NSPredicate(format: "label == %@", value)
        let expectation = expectation(
            for: predicate,
            evaluatedWith: app.staticTexts["questionCounter"]
        )

        wait(for: [expectation], timeout: 3)
    }
}
