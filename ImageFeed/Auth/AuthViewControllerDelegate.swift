import Foundation

protocol AuthViewControllerDelegate: AnyObject {
    func authViewControllerDidAuthenticate(_ viewController: AuthViewController)
}
