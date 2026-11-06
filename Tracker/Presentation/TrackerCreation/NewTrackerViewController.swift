import UIKit

enum TrackerCreationType {
    case habit
    case irregularEvent
}

protocol NewTrackerViewControllerDelegate: AnyObject {
    func categoryTitles() -> [String]
    func addCategory(title: String)
    func newTrackerViewController(
        _ viewController: NewTrackerViewController,
        didCreate tracker: Tracker,
        categoryTitle: String
    )
}

final class NewTrackerViewController: UIViewController {
    weak var delegate: NewTrackerViewControllerDelegate?

    private let type: TrackerCreationType
    private var selectedDays: Set<Weekday> = []
    private var selectedCategoryTitle: String?
    private var selectedEmojiIndex: Int?
    private var selectedColorIndex: Int?

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

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
            string: "Введите название трекера",
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

    private let optionsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.backgroundColor = .ypBackground
        stack.layer.cornerRadius = 16
        stack.clipsToBounds = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let categoryButton = OptionButton()
    private let scheduleButton = OptionButton()
    private let emojiGrid = PaletteGridView(style: .emoji)
    private let colorGrid = PaletteGridView(style: .color)
    private let cancelButton = UIButton.trackerOutline(title: "Отменить")
    private let createButton = UIButton.trackerFilled(title: "Создать")

    private let buttonBar: UIView = {
        let view = UIView()
        view.backgroundColor = .ypWhite
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init(type: TrackerCreationType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backButtonDisplayMode = .minimal
        switch type {
        case .habit:
            navigationItem.title = "Новая привычка"
        case .irregularEvent:
            navigationItem.title = "Новое нерегулярное событие"
        }
        setupForm()
        setupButtons()
        setupKeyboard()
        updateFormState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.applyTrackerAppearance(usesCompactTitle: true)
    }

    private func setupForm() {
        textField.delegate = self
        textField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)

        categoryButton.configure(title: "Категория", subtitle: nil)
        categoryButton.setSeparatorHidden(type != .habit)
        categoryButton.addTarget(self, action: #selector(categoryTapped), for: .touchUpInside)
        optionsStack.addArrangedSubview(categoryButton)

        if type == .habit {
            scheduleButton.configure(title: "Расписание", subtitle: nil)
            scheduleButton.setSeparatorHidden(true)
            scheduleButton.addTarget(self, action: #selector(scheduleTapped), for: .touchUpInside)
            optionsStack.addArrangedSubview(scheduleButton)
        }

        emojiGrid.onSelect = { [weak self] index in
            self?.selectedEmojiIndex = index
            self?.updateFormState()
        }
        colorGrid.onSelect = { [weak self] index in
            self?.selectedColorIndex = index
            self?.updateFormState()
        }

        let emojiTitle = sectionTitle("Emoji")
        let colorTitle = sectionTitle("Цвет")
        contentStack.addArrangedSubview(textField)
        contentStack.addArrangedSubview(limitLabel)
        contentStack.addArrangedSubview(optionsStack)
        contentStack.addArrangedSubview(emojiTitle)
        contentStack.addArrangedSubview(emojiGrid)
        contentStack.addArrangedSubview(colorTitle)
        contentStack.addArrangedSubview(colorGrid)
        contentStack.setCustomSpacing(24, after: limitLabel)
        contentStack.setCustomSpacing(32, after: optionsStack)
        contentStack.setCustomSpacing(16, after: emojiTitle)
        contentStack.setCustomSpacing(24, after: emojiGrid)
        contentStack.setCustomSpacing(16, after: colorTitle)

        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(equalToConstant: 75),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    private func setupButtons() {
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)

        let buttonsStack = UIStackView(arrangedSubviews: [cancelButton, createButton])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 8
        buttonsStack.distribution = .fillEqually
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false

        buttonBar.addSubview(buttonsStack)
        view.addSubview(buttonBar)
        NSLayoutConstraint.activate([
            buttonBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            buttonsStack.leadingAnchor.constraint(equalTo: buttonBar.leadingAnchor, constant: 20),
            buttonsStack.trailingAnchor.constraint(equalTo: buttonBar.trailingAnchor, constant: -20),
            buttonsStack.topAnchor.constraint(equalTo: buttonBar.topAnchor, constant: 16),
            buttonsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: buttonBar.topAnchor)
        ])
    }

    private func setupKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    private var enteredText: String {
        textField.text ?? ""
    }

    private var trimmedName: String {
        enteredText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isNameValid: Bool {
        !trimmedName.isEmpty && enteredText.count <= 38
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textColor = .ypBlack
        return label
    }

    private var isFormValid: Bool {
        guard isNameValid,
              selectedCategoryTitle != nil,
              selectedEmojiIndex != nil,
              selectedColorIndex != nil else { return false }
        switch type {
        case .habit:
            return !selectedDays.isEmpty
        case .irregularEvent:
            return true
        }
    }

    private func updateFormState() {
        let showsLimit = enteredText.count > 38
        limitLabel.isHidden = !showsLimit
        contentStack.setCustomSpacing(showsLimit ? 8 : 24, after: textField)
        createButton.isEnabled = isFormValid
        createButton.backgroundColor = isFormValid ? .ypBlack : .ypGray
    }

    @objc private func nameChanged() {
        updateFormState()
    }

    @objc private func categoryTapped() {
        let categoryList = CategoryListViewController(selectedTitle: selectedCategoryTitle)
        categoryList.delegate = self
        navigationController?.pushViewController(categoryList, animated: true)
    }

    @objc private func scheduleTapped() {
        let scheduleViewController = ScheduleViewController(selectedDays: selectedDays)
        scheduleViewController.delegate = self
        navigationController?.pushViewController(scheduleViewController, animated: true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func createTapped() {
        guard isFormValid,
              let emojiIndex = selectedEmojiIndex,
              let colorIndex = selectedColorIndex else { return }
        let schedule: TrackerSchedule
        switch type {
        case .habit:
            schedule = .habit(selectedDays)
        case .irregularEvent:
            schedule = .irregular
        }
        let tracker = Tracker(
            id: UUID(),
            name: trimmedName,
            color: TrackerPalette.color(at: colorIndex),
            emoji: TrackerPalette.emoji(at: emojiIndex),
            schedule: schedule
        )
        guard let categoryTitle = selectedCategoryTitle else { return }
        delegate?.newTrackerViewController(self, didCreate: tracker, categoryTitle: categoryTitle)
        dismiss(animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        let keyboardFrame = view.convert(frame, from: view.window)
        let overlap = max(0, view.bounds.maxY - keyboardFrame.origin.y)
        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset.bottom = overlap
            self.scrollView.verticalScrollIndicatorInsets.bottom = overlap
        }
        if overlap > 0 {
            let fieldFrame = textField.convert(textField.bounds, to: scrollView)
            scrollView.scrollRectToVisible(fieldFrame.insetBy(dx: 0, dy: -12), animated: true)
        }
    }
}

extension NewTrackerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension NewTrackerViewController: CategoryListViewControllerDelegate {
    func categoryTitles() -> [String] {
        delegate?.categoryTitles() ?? []
    }

    func categoryListDidCreateCategory(_ title: String) {
        delegate?.addCategory(title: title)
    }

    func categoryList(_ viewController: CategoryListViewController, didSelect title: String) {
        selectedCategoryTitle = title
        categoryButton.configure(title: "Категория", subtitle: title)
        updateFormState()
    }
}

extension NewTrackerViewController: ScheduleViewControllerDelegate {
    func scheduleViewController(_ viewController: ScheduleViewController, didSelect days: Set<Weekday>) {
        selectedDays = days
        let summary = Weekday.summary(for: days)
        scheduleButton.configure(title: "Расписание", subtitle: summary.isEmpty ? nil : summary)
        updateFormState()
    }
}

final class PaddedTextField: UITextField {
    private let textPadding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 36)

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textPadding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textPadding)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: textPadding)
    }

    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        super.clearButtonRect(forBounds: bounds).offsetBy(dx: -6, dy: 0)
    }
}
