import UIKit

final class StatisticsViewController: UIViewController {
    private let categoryStore = TrackerCategoryStore()
    private lazy var trackerStore = TrackerStore(categoryStore: categoryStore)
    private lazy var recordStore = TrackerRecordStore(trackerStore: trackerStore)

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let cardsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let bestCard = StatisticCardView()
    private let idealCard = StatisticCardView()
    private let completedCard = StatisticCardView()
    private let averageCard = StatisticCardView()

    private lazy var emptyStateView = EmptyStateView(
        imageName: "StubStatistics",
        text: L10n.text("statistics.empty"),
        rendersAsTemplate: true
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        navigationItem.title = L10n.text("statistics.title")
        navigationItem.largeTitleDisplayMode = .always
        setupLayout()
        recordStore.delegate = self
        categoryStore.delegate = self
        trackerStore.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    private func setupLayout() {
        cardsStack.addArrangedSubview(bestCard)
        cardsStack.addArrangedSubview(idealCard)
        cardsStack.addArrangedSubview(completedCard)
        cardsStack.addArrangedSubview(averageCard)
        scrollView.addSubview(cardsStack)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        view.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cardsStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            cardsStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            cardsStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            cardsStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),

            emptyStateView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func reload() {
        let summary = StatisticsCalculator.summary(
            categories: categoryStore.categories(),
            records: recordStore.records()
        )
        let showsEmpty = !summary.hasData
        emptyStateView.isHidden = !showsEmpty
        scrollView.isHidden = showsEmpty
        bestCard.configure(value: summary.bestPeriod, title: L10n.text("statistics.best"))
        idealCard.configure(value: summary.idealDays, title: L10n.text("statistics.ideal"))
        completedCard.configure(value: summary.completed, title: L10n.text("statistics.completed"))
        averageCard.configure(value: summary.average, title: L10n.text("statistics.average"))
    }
}

extension StatisticsViewController: TrackerRecordStoreDelegate, TrackerStoreDelegate, TrackerCategoryStoreDelegate {
    func trackerRecordStoreDidUpdate() {
        reload()
    }

    func trackerStoreDidUpdate() {
        reload()
    }

    func trackerCategoryStoreDidUpdate() {
        reload()
    }
}

private final class StatisticCardView: UIView {
    private let gradientLayer = CAGradientLayer()
    private let innerView = UIView()
    private let valueLabel = UILabel()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 16
        gradientLayer.colors = [
            UIColor(hex: 0xFD4C49).cgColor,
            UIColor(hex: 0x46E69D).cgColor,
            UIColor(hex: 0x007BFA).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.cornerRadius = 16
        layer.addSublayer(gradientLayer)

        innerView.backgroundColor = .ypWhite
        innerView.layer.cornerRadius = 15
        innerView.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.font = .systemFont(ofSize: 34, weight: .bold)
        valueLabel.textColor = .ypBlack
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .ypBlack
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(innerView)
        innerView.addSubview(valueLabel)
        innerView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 90),
            innerView.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            innerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 1),
            innerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1),
            innerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),
            valueLabel.leadingAnchor.constraint(equalTo: innerView.leadingAnchor, constant: 12),
            valueLabel.trailingAnchor.constraint(equalTo: innerView.trailingAnchor, constant: -12),
            valueLabel.topAnchor.constraint(equalTo: innerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: valueLabel.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: valueLabel.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: innerView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func configure(value: Int, title: String) {
        valueLabel.text = "\(value)"
        titleLabel.text = title
    }
}
