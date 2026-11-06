import UIKit

final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [makeTrackersNavigation(), makeStatisticsNavigation()]
        setupAppearance()
    }

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .ypWhite
        appearance.shadowColor = UIColor.ypGray.withAlphaComponent(0.3)

        let itemAppearance = UITabBarItemAppearance()
        let font = UIFont.systemFont(ofSize: 10, weight: .medium)
        itemAppearance.normal.iconColor = .ypGray
        itemAppearance.normal.titleTextAttributes = [
            .font: font,
            .foregroundColor: UIColor.ypGray
        ]
        itemAppearance.selected.iconColor = .ypBlue
        itemAppearance.selected.titleTextAttributes = [
            .font: font,
            .foregroundColor: UIColor.ypBlue
        ]
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.isTranslucent = false
    }

    private func makeTrackersNavigation() -> UINavigationController {
        let navigation = UINavigationController(rootViewController: TrackersViewController())
        navigation.tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: UIImage(systemName: "circle"),
            selectedImage: UIImage(systemName: "circle")
        )
        navigation.navigationBar.applyTrackerAppearance(usesCompactTitle: false)
        navigation.navigationBar.prefersLargeTitles = true
        return navigation
    }

    private func makeStatisticsNavigation() -> UINavigationController {
        let navigation = UINavigationController(rootViewController: StatisticsViewController())
        navigation.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: UIImage(systemName: "hare"),
            selectedImage: UIImage(systemName: "hare")
        )
        navigation.navigationBar.applyTrackerAppearance(usesCompactTitle: false)
        navigation.navigationBar.prefersLargeTitles = true
        return navigation
    }
}
