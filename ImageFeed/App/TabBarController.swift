import UIKit

final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let feedIcon = UIImage(named: "tab_editorial_active")?.withRenderingMode(.alwaysOriginal)
        let profileIcon = UIImage(named: "tab_profile_active")?.withRenderingMode(.alwaysOriginal)

        let imagesListViewController = ImagesListViewController()
        imagesListViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: feedIcon,
            selectedImage: feedIcon
        )

        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let profileViewController = storyboard.instantiateViewController(
            withIdentifier: "ProfileViewController"
        )
        profileViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: profileIcon,
            selectedImage: profileIcon
        )

        viewControllers = [imagesListViewController, profileViewController]

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .ypBlack
        appearance.stackedLayoutAppearance.normal.iconColor = .ypGray
        appearance.stackedLayoutAppearance.selected.iconColor = .ypWhite
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}
