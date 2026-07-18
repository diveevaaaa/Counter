import UIKit

enum AlertPresenter {
    static func showLoginError(on viewController: UIViewController, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default) { _ in
            completion?()
        })
        viewController.present(alert, animated: true)
    }
}
