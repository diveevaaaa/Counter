import UIKit

final class CatalogCell: UITableViewCell {
    static let reuseIdentifier = "CatalogCell"

    private let coverView = UIImageView()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private var coverURL: URL?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white

        coverView.translatesAutoresizingMaskIntoConstraints = false
        coverView.contentMode = .scaleAspectFill
        coverView.clipsToBounds = true
        coverView.layer.cornerRadius = 12
        coverView.backgroundColor = UIColor(white: 0.95, alpha: 1)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = UIColor(red: 26 / 255, green: 27 / 255, blue: 34 / 255, alpha: 1)
        titleLabel.numberOfLines = 1

        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.font = .systemFont(ofSize: 15, weight: .regular)
        countLabel.textColor = UIColor(red: 26 / 255, green: 27 / 255, blue: 34 / 255, alpha: 1)

        contentView.addSubview(coverView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)

        NSLayoutConstraint.activate([
            coverView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            coverView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            coverView.heightAnchor.constraint(equalToConstant: 140),

            titleLabel.topAnchor.constraint(equalTo: coverView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: coverView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: coverView.trailingAnchor),

            countLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            countLabel.leadingAnchor.constraint(equalTo: coverView.leadingAnchor),
            countLabel.trailingAnchor.constraint(equalTo: coverView.trailingAnchor),
            countLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -13)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ model: CatalogCellModel) {
        titleLabel.text = model.title
        countLabel.text = model.countText
        coverURL = model.coverURL
        coverView.image = nil
        guard let url = model.coverURL else { return }
        ImageLoader.shared.load(url) { [weak self] image in
            guard let self, self.coverURL == url else { return }
            self.coverView.image = image
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverURL = nil
        coverView.image = nil
    }
}
