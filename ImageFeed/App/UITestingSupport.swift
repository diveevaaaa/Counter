import Foundation

#if DEBUG
enum UITestingSupport {
    private static let didConsumeAuthenticatedLaunchKey = "UITestingSupport.didConsumeAuthenticatedLaunch"

    static var isUITesting: Bool {
        CommandLine.arguments.contains("-ui-testing")
    }

    static var shouldStartAuthenticated: Bool {
        CommandLine.arguments.contains("-ui-testing-authenticated")
    }

    static func resetStateForLaunchIfNeeded() {
        guard isUITesting else { return }

        UserDefaults.standard.removeObject(forKey: didConsumeAuthenticatedLaunchKey)
        OAuth2TokenStorage.shared.clearToken()
        ProfileService.shared.clearProfile()
        ProfileImageService.shared.clearProfileImage()
    }

    static func consumeAuthenticatedLaunchIfNeeded() -> Bool {
        guard isUITesting, shouldStartAuthenticated else { return false }

        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: didConsumeAuthenticatedLaunchKey) else { return false }

        defaults.set(true, forKey: didConsumeAuthenticatedLaunchKey)
        configureAuthenticatedState()
        return true
    }

    private static func configureAuthenticatedState() {
        OAuth2TokenStorage.shared.token = "ui-testing-token"
        ProfileService.shared.setProfile(
            Profile(
                username: "ekaterina_nov",
                name: "Екатерина Новикова",
                loginName: "@ekaterina_nov",
                bio: "Hello, World!"
            )
        )
        ProfileImageService.shared.setAvatarURL(nil)
    }
}
#endif
