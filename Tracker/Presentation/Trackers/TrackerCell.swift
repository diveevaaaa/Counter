import UIKit

struct TrackerCellModel {
    let emoji: String
    let name: String
    let color: UIColor
    let daysText: String
    let isCompleted: Bool
    let isCompleteButtonEnabled: Bool
}

protocol TrackerCellDelegate: AnyObject {
    func trackerCellDidTapCompleteButton(_ cell: TrackerCell)
}

final class TrackerCell: UICollectionViewCell {
    static let reuseIdentifier = "TrackerCell"

    weak var delegate: TrackerCellDelegate?

    private let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let daysLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .ypBlack
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let completeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .white
        button.layer.cornerRadius = 17
        button.clipsToBounds = true
        button.layer.masksToBounds = true
        button.adjustsImageWhenDisabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(colorView)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(daysLabel)
        contentView.addSubview(completeButton)
        completeButton.addTarget(self, action: #selector(completeTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            colorView.topAnchor.constraint(equalTo: contentView.topAnchor),
            colorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            colorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            colorView.heightAnchor.constraint(equalToConstant: 90),

            emojiLabel.topAnchor.constraint(equalTo: colorView.topAnchor, constant: 12),
            emojiLabel.leadingAnchor.constraint(equalTo: colorView.leadingAnchor, constant: 12),
            emojiLabel.widthAnchor.constraint(equalToConstant: 24),
            emojiLabel.heightAnchor.constraint(equalToConstant: 24),

            nameLabel.leadingAnchor.constraint(equalTo: colorView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: -12),
            nameLabel.bottomAnchor.constraint(equalTo: colorView.bottomAnchor, constant: -12),

            completeButton.topAnchor.constraint(equalTo: colorView.bottomAnchor, constant: 8),
            completeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            completeButton.widthAnchor.constraint(equalToConstant: 34),
            completeButton.heightAnchor.constraint(equalToConstant: 34),

            daysLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            daysLabel.centerYAnchor.constraint(equalTo: completeButton.centerYAnchor),
            daysLabel.trailingAnchor.constraint(lessThanOrEqualTo: completeButton.leadingAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        emojiLabel.text = nil
        nameLabel.text = nil
        daysLabel.text = nil
        completeButton.setImage(nil, for: .normal)
        delegate = nil
    }

    func configure(with model: TrackerCellModel) {
        emojiLabel.text = model.emoji
        nameLabel.text = model.name
        colorView.backgroundColor = model.color
        daysLabel.text = model.daysText
        let backgroundAlpha: CGFloat = model.isCompleted ? 0.3 : 1
        completeButton.backgroundColor = model.color.withAlphaComponent(backgroundAlpha)
        completeButton.isEnabled = model.isCompleteButtonEnabled
        let symbolName = model.isCompleted ? "checkmark" : "plus"
        completeButton.setImage(
            UIImage(systemName: symbolName, withConfiguration: symbolConfiguration),
            for: .normal
        )
        completeButton.accessibilityLabel = model.isCompleted ? "Снять отметку" : "Отметить выполненной"
    }

    @objc private func completeTapped() {
        delegate?.trackerCellDidTapCompleteButton(self)
    }
}
