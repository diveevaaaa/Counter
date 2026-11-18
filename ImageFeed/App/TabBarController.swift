import UIKit

final class TabBarController: UITabBarController {
    override func awakeFromNib() {
        super.awakeFromNib()
        setupViewControllers()
        setupAppearance()
    }

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .ypBlack
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.3)

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }

    private func setupViewControllers() {
        let feedInactiveIcon = UIImage(named: "tab_editorial_no_active")?.withRenderingMode(.alwaysOriginal)
        let feedActiveIcon = UIImage(named: "tab_editorial_active")?.withRenderingMode(.alwaysOriginal)
        let profileInactiveIcon = UIImage(named: "tab_profile_no_active")?.withRenderingMode(.alwaysOriginal)
        let profileActiveIcon = UIImage(named: "tab_profile_active")?.withRenderingMode(.alwaysOriginal)

        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let imagesListViewController = storyboard.instantiateViewController(
            withIdentifier: "ImagesListViewController"
        )
        imagesListViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: feedInactiveIcon,
            selectedImage: feedActiveIcon
        )

        let profileViewController = storyboard.instantiateViewController(
            withIdentifier: "ProfileViewController"
        )
        profileViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: profileInactiveIcon,
            selectedImage: profileActiveIcon
        )

        viewControllers = [imagesListViewController, profileViewController]
    }
}
