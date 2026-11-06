import UIKit

protocol ScheduleViewControllerDelegate: AnyObject {
    func scheduleViewController(_ viewController: ScheduleViewController, didSelect days: Set<Weekday>)
}

final class ScheduleViewController: UIViewController {
    weak var delegate: ScheduleViewControllerDelegate?

    private var selectedDays: Set<Weekday>
    private let days = Weekday.allCases

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .ypBackground
        tableView.separatorStyle = .none
        tableView.rowHeight = 75
        tableView.layer.cornerRadius = 16
        tableView.layer.masksToBounds = true
        tableView.sectionHeaderTopPadding = 0
        tableView.alwaysBounceVertical = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private let doneButton = UIButton.trackerFilled(title: "Готово")

    init(selectedDays: Set<Weekday>) {
        self.selectedDays = selectedDays
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        navigationItem.title = "Расписание"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backButtonDisplayMode = .minimal

        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tableView.register(ScheduleCell.self, forCellReuseIdentifier: ScheduleCell.reuseIdentifier)

        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        view.addSubview(tableView)
        view.addSubview(doneButton)

        let contentHeight = tableView.heightAnchor.constraint(
            equalToConstant: 75 * CGFloat(days.count)
        )
        contentHeight.priority = UILayoutPriority(999)
        let bottomLimit = tableView.bottomAnchor.constraint(
            lessThanOrEqualTo: doneButton.topAnchor,
            constant: -16
        )
        let bottomStretch = tableView.bottomAnchor.constraint(
            equalTo: doneButton.topAnchor,
            constant: -16
        )
        bottomStretch.priority = UILayoutPriority(750)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            contentHeight,
            bottomLimit,
            bottomStretch,
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.applyTrackerAppearance(usesCompactTitle: true)
    }

    @objc private func doneTapped() {
        delegate?.scheduleViewController(self, didSelect: selectedDays)
        navigationController?.popViewController(animated: true)
    }
}

extension ScheduleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        days.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ScheduleCell.reuseIdentifier,
            for: indexPath
        ) as? ScheduleCell else {
            return UITableViewCell()
        }
        let day = days[indexPath.row]
        cell.configure(
            title: day.fullTitle,
            isOn: selectedDays.contains(day),
            showsSeparator: indexPath.row < days.count - 1
        ) { [weak self] isOn in
            guard let self else { return }
            if isOn {
                self.selectedDays.insert(day)
            } else {
                self.selectedDays.remove(day)
            }
        }
        return cell
    }
}

private final class ScheduleCell: UITableViewCell {
    static let reuseIdentifier = "ScheduleCell"

    private var onToggle: ((Bool) -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.textColor = .ypBlack
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let daySwitch: UISwitch = {
        let daySwitch = UISwitch()
        daySwitch.onTintColor = .ypBlue
        daySwitch.translatesAutoresizingMaskIntoConstraints = false
        return daySwitch
    }()

    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ypGray.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        contentView.addSubview(daySwitch)
        contentView.addSubview(separator)
        daySwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: daySwitch.leadingAnchor, constant: -12),
            daySwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            daySwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onToggle = nil
    }

    func configure(title: String, isOn: Bool, showsSeparator: Bool, onToggle: @escaping (Bool) -> Void) {
        titleLabel.text = title
        separator.isHidden = !showsSeparator
        daySwitch.setOn(isOn, animated: false)
        self.onToggle = onToggle
    }

    @objc private func switchChanged() {
        onToggle?(daySwitch.isOn)
    }
}
