import XCTest

final class ImageFeedUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testAuth() throws {
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let authButton = app.buttons["AuthLoginButton"]
        XCTAssertTrue(authButton.waitForExistence(timeout: 5))
        authButton.tap()

        let webView = app.webViews["AuthWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 10))

        let environment = ProcessInfo.processInfo.environment
        guard let email = environment["UNSPLASH_TEST_EMAIL"], !email.isEmpty,
              let password = environment["UNSPLASH_TEST_PASSWORD"], !password.isEmpty else {
            throw XCTSkip("Set UNSPLASH_TEST_EMAIL and UNSPLASH_TEST_PASSWORD to run the real auth UI test.")
        }

        let emailTextField = webView.textFields.element(boundBy: 0)
        XCTAssertTrue(emailTextField.waitForExistence(timeout: 10))
        emailTextField.tap()
        emailTextField.typeText(email)

        let passwordTextField = webView.secureTextFields.element(boundBy: 0)
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 5))
        passwordTextField.tap()
        passwordTextField.typeText(password)

        let loginButton = webView.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@", "Login", "Войти")
        ).element(boundBy: 0)
        XCTAssertTrue(loginButton.waitForExistence(timeout: 5))
        loginButton.tap()

        let feedTable = app.tables["ImagesListTableView"]
        XCTAssertTrue(feedTable.waitForExistence(timeout: 20))
    }

    func testFeed() throws {
        launchAuthenticatedApp()

        let feedTable = app.tables["ImagesListTableView"]
        XCTAssertTrue(feedTable.waitForExistence(timeout: 5))
        feedTable.swipeUp()

        let firstCell = feedTable.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))

        let likeButton = firstCell.buttons["ImagesListCellLikeButton"]
        XCTAssertTrue(likeButton.waitForExistence(timeout: 5))
        likeButton.tap()
        likeButton.tap()

        firstCell.tap()

        let imageScrollView = app.scrollViews["SingleImageScrollView"]
        XCTAssertTrue(imageScrollView.waitForExistence(timeout: 5))
        imageScrollView.pinch(withScale: 2.0, velocity: 1.0)
        imageScrollView.pinch(withScale: 0.5, velocity: -1.0)

        app.buttons["SingleImageBackButton"].tap()
        XCTAssertTrue(feedTable.waitForExistence(timeout: 5))
    }

    func testProfile() throws {
        launchAuthenticatedApp()

        let feedTable = app.tables["ImagesListTableView"]
        XCTAssertTrue(feedTable.waitForExistence(timeout: 5))

        profileTabButton.tap()

        XCTAssertTrue(app.staticTexts["Екатерина Новикова"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["@ekaterina_nov"].exists)
        XCTAssertTrue(app.staticTexts["Hello, World!"].exists)

        app.buttons["ProfileLogoutButton"].tap()

        let logoutAlert = app.alerts["Пока, пока!"]
        XCTAssertTrue(logoutAlert.waitForExistence(timeout: 5))
        logoutAlert.buttons["Да"].tap()

        XCTAssertTrue(app.buttons["AuthLoginButton"].waitForExistence(timeout: 5))
    }

    private func launchAuthenticatedApp() {
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-authenticated"]
        app.launch()
    }

    private var profileTabButton: XCUIElement {
        let identifiedButton = app.tabBars.buttons["ProfileTab"]
        if identifiedButton.exists {
            return identifiedButton
        }
        return app.tabBars.buttons.element(boundBy: 1)
    }
}
