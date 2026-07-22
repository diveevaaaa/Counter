import XCTest
@testable import ImageFeed

final class ImagesListViewControllerTests: XCTestCase {
    func testViewDidLoadConfiguresTableView() {
        let viewController = ImagesListViewController()

        viewController.loadViewIfNeeded()

        XCTAssertNotNil(viewController.tableView.dataSource as? ImagesListViewController)
        XCTAssertNotNil(viewController.tableView.delegate as? ImagesListViewController)
        XCTAssertEqual(viewController.tableView.accessibilityIdentifier, "ImagesListTableView")
    }

    func testNumberOfRowsEqualsPhotosCount() {
        let viewController = ImagesListViewController()

        viewController.loadViewIfNeeded()
        let rowsCount = viewController.tableView(
            viewController.tableView,
            numberOfRowsInSection: 0
        )

        XCTAssertEqual(rowsCount, Photo.makeMockPhotos().count)
    }

    func testToggleLikeChangesPhotoState() {
        let viewController = ImagesListViewController()

        viewController.loadViewIfNeeded()
        let initialState = viewController.photos[0].isLiked
        viewController.toggleLike(at: IndexPath(row: 0, section: 0))

        XCTAssertEqual(viewController.photos[0].isLiked, !initialState)
    }
}
