import UIKit
import Kingfisher

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"

    @IBOutlet private weak var cellImageView: UIImageView!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var likeButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cellImageView.contentMode = .scaleAspectFill
        cellImageView.clipsToBounds = true
        cellImageView.layer.cornerRadius = 16
        cellImageView.layer.masksToBounds = true

        dateLabel.font = UIFont(name: "SF Pro Text", size: 13) ?? .systemFont(ofSize: 13)
        dateLabel.textColor = .white
    }

    func configure(with photo: Photo) {
        cellImageView.kf.indicatorType = .activity
        cellImageView.kf.setImage(with: URL(string: photo.thumbImageURL))
        if let createdAt = photo.createdAt {
            dateLabel.text = ImagesListCell.dateFormatter.string(from: createdAt)
        } else {
            dateLabel.text = ""
        }
        setIsLiked(photo.isLiked)
    }

    func setIsLiked(_ isLiked: Bool) {
        let imageName = isLiked ? "likeActive" : "likeNoActive"
        likeButton.setImage(UIImage(named: imageName), for: .normal)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
}
