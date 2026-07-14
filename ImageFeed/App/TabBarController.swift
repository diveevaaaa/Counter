import UIKit

final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let imagesListViewController = ImagesListViewController()
        imagesListViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "listTabIcon"),
            selectedImage: nil
        )

        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let profileViewController = storyboard.instantiateViewController(
            withIdentifier: "ProfileViewController"
        )
        profileViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "profileTabIcon"),
            selectedImage: nil
        )

        viewControllers = [imagesListViewController, profileViewController]

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .ypBlack
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .ypWhite
        tabBar.unselectedItemTintColor = .ypGray
    }
}
