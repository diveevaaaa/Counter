import XCTest
@testable import ImageFeed

final class ProfileViewControllerTests: XCTestCase {
    func testViewDidLoadShowsProfileDetails() throws {
        let profile = Profile(
            username: "ekaterina_nov",
            name: "Екатерина Новикова",
            loginName: "@ekaterina_nov",
            bio: "Hello, World!"
        )
        let viewController = makeViewController(profile: profile)

        viewController.loadViewIfNeeded()

        let nameLabel = try XCTUnwrap(viewController.view.label(withIdentifier: "ProfileNameLabel"))
        let loginLabel = try XCTUnwrap(viewController.view.label(withIdentifier: "ProfileLoginNameLabel"))
        let descriptionLabel = try XCTUnwrap(viewController.view.label(withIdentifier: "ProfileDescriptionLabel"))

        XCTAssertEqual(nameLabel.text, "Екатерина Новикова")
        XCTAssertEqual(loginLabel.text, "@ekaterina_nov")
        XCTAssertEqual(descriptionLabel.text, "Hello, World!")
    }

    func testViewDidLoadConfiguresLogoutButton() throws {
        let viewController = makeViewController(profile: nil)

        viewController.loadViewIfNeeded()

        let logoutButton = try XCTUnwrap(viewController.view.viewWithAccessibilityIdentifier("ProfileLogoutButton") as? UIButton)
        XCTAssertNotNil(logoutButton.image(for: .normal))
    }

    private func makeViewController(profile: Profile?) -> ProfileViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: ProfileViewController.self))
        let viewController = storyboard.instantiateViewController(
            withIdentifier: "ProfileViewController"
        ) as! ProfileViewController
        viewController.profileService = ProfileServiceMock(profile: profile)
        viewController.profileImageService = ProfileImageServiceMock(avatarURL: nil)
        return viewController
    }
}

private final class ProfileServiceMock: ProfileServiceProtocol {
    var profile: Profile?

    init(profile: Profile?) {
        self.profile = profile
    }

    func clearProfile() {
        profile = nil
    }
}

private final class ProfileImageServiceMock: ProfileImageServiceProtocol {
    var avatarURL: String?

    init(avatarURL: String?) {
        self.avatarURL = avatarURL
    }

    func clearProfileImage() {
        avatarURL = nil
    }
}

private extension UIView {
    func label(withIdentifier identifier: String) -> UILabel? {
        viewWithAccessibilityIdentifier(identifier) as? UILabel
    }

    func viewWithAccessibilityIdentifier(_ identifier: String) -> UIView? {
        if accessibilityIdentifier == identifier {
            return self
        }

        for subview in subviews {
            if let view = subview.viewWithAccessibilityIdentifier(identifier) {
                return view
            }
        }

        return nil
    }
}
