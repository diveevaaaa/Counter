import UIKit

protocol ImagesListCellDelegate: AnyObject {
    func imagesListCellDidTapLike(_ cell: ImagesListCell)
}

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"

    private enum IconName {
        static let liked = "likeActive"
        static let notLiked = "likeNoActive"
    }

    weak var delegate: ImagesListCellDelegate?

    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        return imageView
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .ypWhite
        label.shadowColor = UIColor.black.withAlphaComponent(0.35)
        label.shadowOffset = CGSize(width: 0, height: 1)
        return label
    }()

    private let likeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.adjustsImageWhenHighlighted = false
        return button
    }()

    private var aspectRatioConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .ypBlack
        contentView.backgroundColor = .ypBlack
        addSubviews()
        setupConstraints()
        likeButton.addTarget(self, action: #selector(didTapLikeButton), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        photoImageView.image = nil
        aspectRatioConstraint?.isActive = false
        aspectRatioConstraint = nil
    }

    func configure(with photo: Photo, dateText: String) {
        dateLabel.text = dateText
        photoImageView.image = UIImage(named: "Dogs/\(photo.imageName)") ?? UIImage(named: photo.imageName)

        let ratio = photo.size.height / photo.size.width
        aspectRatioConstraint = photoImageView.heightAnchor.constraint(equalTo: photoImageView.widthAnchor, multiplier: ratio)
        aspectRatioConstraint?.priority = .required
        aspectRatioConstraint?.isActive = true

        updateLikeState(isLiked: photo.isLiked)
    }

    func updateLikeState(isLiked: Bool) {
        let imageName = isLiked ? IconName.liked : IconName.notLiked
        likeButton.setBackgroundImage(UIImage(named: imageName), for: .normal)
    }

    private func addSubviews() {
        contentView.addSubview(photoImageView)
        photoImageView.addSubview(dateLabel)
        photoImageView.addSubview(likeButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            photoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            photoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            photoImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            dateLabel.leadingAnchor.constraint(equalTo: photoImageView.leadingAnchor, constant: 8),
            dateLabel.bottomAnchor.constraint(equalTo: photoImageView.bottomAnchor, constant: -8),

            likeButton.topAnchor.constraint(equalTo: photoImageView.topAnchor),
            likeButton.trailingAnchor.constraint(equalTo: photoImageView.trailingAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 42),
            likeButton.heightAnchor.constraint(equalTo: likeButton.widthAnchor)
        ])
    }

    @objc
    private func didTapLikeButton() {
        delegate?.imagesListCellDidTapLike(self)
    }
}
