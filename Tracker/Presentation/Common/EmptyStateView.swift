import UIKit

final class EmptyStateView: UIView {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .ypBlack
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .ypBlack
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var rendersAsTemplate: Bool

    init(imageName: String, text: String, rendersAsTemplate: Bool = false) {
        self.rendersAsTemplate = rendersAsTemplate
        super.init(frame: .zero)
        let stack = UIStackView(arrangedSubviews: [imageView, messageLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 250)
        ])
        update(imageName: imageName, text: text)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(imageName: String, text: String, rendersAsTemplate: Bool? = nil) {
        if let rendersAsTemplate {
            self.rendersAsTemplate = rendersAsTemplate
        }
        let image = UIImage(named: imageName)
        imageView.image = self.rendersAsTemplate
            ? image?.withRenderingMode(.alwaysTemplate)
            : image?.withRenderingMode(.alwaysOriginal)
        messageLabel.text = text
    }
}
