import UIKit

final class UIBlockingProgressHUD {
    private static let overlayTag = 9_999
    private(set) static var isBlocking = false

    static func show() {
        DispatchQueue.main.async {
            guard let window = activeWindow() else { return }
            guard window.viewWithTag(overlayTag) == nil else { return }

            isBlocking = true
            window.isUserInteractionEnabled = false

            let overlay = UIView(frame: window.bounds)
            overlay.tag = overlayTag
            overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)

            let indicator = UIActivityIndicatorView(style: .large)
            indicator.color = .white
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.startAnimating()

            overlay.addSubview(indicator)
            NSLayoutConstraint.activate([
                indicator.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                indicator.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
            ])

            window.addSubview(overlay)
        }
    }

    static func dismiss() {
        DispatchQueue.main.async {
            isBlocking = false

            guard let window = activeWindow() else { return }

            window.isUserInteractionEnabled = true
            window.viewWithTag(overlayTag)?.removeFromSuperview()
        }
    }

    static func reset() {
        dismiss()
    }

    private static func activeWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}
