import XCTest
@testable import ImageFeed

final class WebViewPresenterTests: XCTestCase {
    func testPresenterCallsLoadRequest() {
        let viewController = WebViewViewControllerSpy()
        let authHelper = AuthHelperStub(
            request: URLRequest(url: URL(string: "https://example.com/auth")!)
        )
        let presenter = WebViewPresenter(authHelper: authHelper)
        presenter.view = viewController

        presenter.viewDidLoad()

        XCTAssertTrue(viewController.didCallLoadRequest)
        XCTAssertEqual(viewController.loadedRequest?.url, URL(string: "https://example.com/auth"))
    }

    func testProgressHiddenWhenOne() {
        let presenter = WebViewPresenter()

        XCTAssertTrue(presenter.shouldHideProgress(for: 1.0))
    }

    func testCodeFromURL() {
        let authHelper = AuthHelper()
        let url = URL(string: "https://unsplash.com/oauth/authorize/native?code=test_code")!

        let code = authHelper.code(from: url)

        XCTAssertEqual(code, "test_code")
    }
}

private final class WebViewViewControllerSpy: WebViewViewControllerProtocol {
    var presenter: WebViewPresenterProtocol?
    private(set) var didCallLoadRequest = false
    private(set) var loadedRequest: URLRequest?

    func load(request: URLRequest) {
        didCallLoadRequest = true
        loadedRequest = request
    }

    func setProgressValue(_ newValue: Float) {}
    func setProgressHidden(_ isHidden: Bool) {}
}

private final class AuthHelperStub: AuthHelperProtocol {
    private let request: URLRequest?

    init(request: URLRequest?) {
        self.request = request
    }

    func authRequest() -> URLRequest? {
        request
    }

    func code(from url: URL) -> String? {
        nil
    }
}
