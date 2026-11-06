import UIKit

protocol CategoryListViewControllerDelegate: AnyObject {
    func categoryTitles() -> [String]
    func categoryListDidCreateCategory(_ title: String)
    func categoryList(_ viewController: CategoryListViewController, didSelect title: String)
}

protocol NewCategoryViewControllerDelegate: AnyObject {
    func newCategoryViewController(_ viewController: NewCategoryViewController, didCreate title: String)
}

final class CategoryListViewController: UIViewController {
    weak var delegate: CategoryListViewControllerDelegate?

    private var titles: [String] = []
    private var selectedTitle: String?
    private var tableHeightConstraint: NSLayoutConstraint?

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

    private let emptyStateView = EmptyStateView(
        imageName: "StubTrackers",
        text: "Привычки и события можно\nобъединить по смыслу"
    )

    private let addButton = UIButton.trackerFilled(title: "Добавить категорию")

    init(selectedTitle: String?) {
        self.selectedTitle = selectedTitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        navigationItem.title = "Категория"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backButtonDisplayMode = .minimal

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.reuseIdentifier)

        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(addButton)

        let height = tableView.heightAnchor.constraint(equalToConstant: 0)
        height.priority = UILayoutPriority(999)
        tableHeightConstraint = height
        let bottomLimit = tableView.bottomAnchor.constraint(
            lessThanOrEqualTo: addButton.topAnchor,
            constant: -16
        )
        let bottomStretch = tableView.bottomAnchor.constraint(
            equalTo: addButton.topAnchor,
            constant: -16
        )
        bottomStretch.priority = UILayoutPriority(750)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomLimit,
            bottomStretch,
            height,
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -30),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.applyTrackerAppearance(usesCompactTitle: true)
        titles = delegate?.categoryTitles() ?? []
        reloadList()
    }

    private func reloadList() {
        let isEmpty = titles.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        tableHeightConstraint?.constant = 75 * CGFloat(titles.count)
        tableView.reloadData()
    }

    @objc private func addTapped() {
        let viewController = NewCategoryViewController()
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension CategoryListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        titles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CategoryCell.reuseIdentifier,
            for: indexPath
        ) as? CategoryCell else {
            return UITableViewCell()
        }
        let title = titles[indexPath.row]
        cell.configure(
            title: title,
            isSelected: title == selectedTitle,
            showsSeparator: indexPath.row < titles.count - 1
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let title = titles[indexPath.row]
        selectedTitle = title
        delegate?.categoryList(self, didSelect: title)
        navigationController?.popViewController(animated: true)
    }
}

extension CategoryListViewController: NewCategoryViewControllerDelegate {
    func newCategoryViewController(_ viewController: NewCategoryViewController, didCreate title: String) {
        delegate?.categoryListDidCreateCategory(title)
    }
}

final class NewCategoryViewController: UIViewController {
    weak var delegate: NewCategoryViewControllerDelegate?

    private let textField: PaddedTextField = {
        let textField = PaddedTextField()
        textField.backgroundColor = .ypBackground
        textField.font = .systemFont(ofSize: 17)
        textField.textColor = .ypBlack
        textField.tintColor = .ypBlue
        textField.layer.cornerRadius = 16
        textField.layer.masksToBounds = true
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.attributedPlaceholder = NSAttributedString(
            string: "Введите название категории",
            attributes: [
                .foregroundColor: UIColor.ypGray,
                .font: UIFont.systemFont(ofSize: 17)
            ]
        )
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let limitLabel: UILabel = {
        let label = UILabel()
        label.text = "Ограничение 38 символов"
        label.font = .systemFont(ofSize: 17)
        label.textColor = .ypRed
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let doneButton = UIButton.trackerFilled(title: "Готово")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        navigationItem.title = "Новая категория"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backButtonDisplayMode = .minimal
        textField.delegate = self
        textField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        view.addSubview(textField)
        view.addSubview(limitLabel)
        view.addSubview(doneButton)
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textField.heightAnchor.constraint(equalToConstant: 75),
            limitLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 8),
            limitLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            limitLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        updateFormState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.applyTrackerAppearance(usesCompactTitle: true)
    }

    private var enteredText: String {
        textField.text ?? ""
    }

    private var trimmedName: String {
        enteredText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func updateFormState() {
        let showsLimit = enteredText.count > 38
        limitLabel.isHidden = !showsLimit
        let isValid = !trimmedName.isEmpty && enteredText.count <= 38
        doneButton.isEnabled = isValid
        doneButton.backgroundColor = isValid ? .ypBlack : .ypGray
    }

    @objc private func nameChanged() {
        updateFormState()
    }

    @objc private func doneTapped() {
        guard doneButton.isEnabled else { return }
        delegate?.newCategoryViewController(self, didCreate: trimmedName)
        navigationController?.popViewController(animated: true)
    }
}

extension NewCategoryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if doneButton.isEnabled {
            doneTapped()
        }
        return true
    }
}

private final class CategoryCell: UITableViewCell {
    static let reuseIdentifier = "CategoryCell"

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.textColor = .ypBlack
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let checkmarkView: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(
                systemName: "checkmark",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            )
        )
        imageView.tintColor = .ypBlue
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
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
        contentView.addSubview(nameLabel)
        contentView.addSubview(checkmarkView)
        contentView.addSubview(separator)
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: checkmarkView.leadingAnchor, constant: -12),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkView.heightAnchor.constraint(equalToConstant: 24),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isSelected: Bool, showsSeparator: Bool) {
        nameLabel.text = title
        checkmarkView.isHidden = !isSelected
        separator.isHidden = !showsSeparator
        accessibilityLabel = title
    }
}
