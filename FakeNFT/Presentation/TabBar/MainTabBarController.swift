import UIKit

final class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let black = UIColor(red: 26 / 255, green: 27 / 255, blue: 34 / 255, alpha: 1)
        tabBar.tintColor = black
        tabBar.unselectedItemTintColor = UIColor(red: 174 / 255, green: 175 / 255, blue: 180 / 255, alpha: 1)
        tabBar.backgroundColor = .white

        viewControllers = [
            navigation(profile),
            navigation(catalog),
            navigation(cart),
            navigation(statistics)
        ]
        selectedIndex = 1
    }

    private var profile: UIViewController {
        let controller = SectionPlaceholderViewController(
            title: "Профиль",
            message: "Профиль входит в другой эпик"
        )
        controller.tabBarItem = UITabBarItem(
            title: "Профиль",
            image: UIImage(systemName: "person.crop.circle"),
            tag: 0
        )
        return controller
    }

    private var catalog: UIViewController {
        let controller = CatalogViewController(viewModel: CatalogViewModel())
        controller.tabBarItem = UITabBarItem(
            title: "Каталог",
            image: UIImage(systemName: "square.stack"),
            tag: 1
        )
        return controller
    }

    private var cart: UIViewController {
        let controller = SectionPlaceholderViewController(
            title: "Корзина",
            message: "Корзина входит в другой эпик"
        )
        controller.tabBarItem = UITabBarItem(
            title: "Корзина",
            image: UIImage(systemName: "bag"),
            tag: 2
        )
        return controller
    }

    private var statistics: UIViewController {
        let controller = SectionPlaceholderViewController(
            title: "Статистика",
            message: "Статистика входит в другой эпик"
        )
        controller.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: UIImage(systemName: "flag"),
            tag: 3
        )
        return controller
    }

    private func navigation(_ root: UIViewController) -> UINavigationController {
        let navigation = UINavigationController(rootViewController: root)
        navigation.navigationBar.prefersLargeTitles = true
        return navigation
    }
}
