import UIKit

extension UINavigationBar {
    func applyTrackerAppearance(usesCompactTitle: Bool) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .ypWhite
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.ypBlack,
            .font: UIFont.systemFont(ofSize: usesCompactTitle ? 16 : 17, weight: usesCompactTitle ? .medium : .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.ypBlack,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        standardAppearance = appearance
        scrollEdgeAppearance = appearance
        compactAppearance = appearance
        compactScrollEdgeAppearance = appearance
        prefersLargeTitles = !usesCompactTitle
        tintColor = .ypBlack
        isTranslucent = false
    }
}
