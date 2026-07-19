import UIKit
import ProgressHUD

final class UIBlockingProgressHUD {
    private(set) static var isBlocking = false

    static func show() {
        DispatchQueue.main.async {
            guard !isBlocking else { return }

            isBlocking = true
            activeWindow()?.isUserInteractionEnabled = false
            ProgressHUD.animate(interaction: false)
        }
    }

    static func dismiss() {
        DispatchQueue.main.async {
            isBlocking = false
            activeWindow()?.isUserInteractionEnabled = true
            ProgressHUD.dismiss()
        }
    }

    private static func activeWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}
