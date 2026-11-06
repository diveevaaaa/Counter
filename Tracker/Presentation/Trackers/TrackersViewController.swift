import UIKit

final class TrackersViewController: UIViewController {
    private let store = TrackerStore()
    private var isRestoring = false

    var categories: [TrackerCategory] = [] {
        didSet {
            reloadTrackers()
            persist()
        }
    }

    var completedTrackers: [TrackerRecord] = [] {
        didSet {
            rebuildCompletedTrackerIds()
            reloadTrackers()
            persist()
        }
    }

    var currentDate: Date = Date() {
        didSet {
            guard !calendar.isDate(oldValue, inSameDayAs: currentDate) else { return }
            rebuildCompletedTrackerIds()
            reloadTrackers()
        }
    }

    private var completedTrackerIds: Set<UUID> = []
    private var lastCollectionWidth: CGFloat = 0
    private var searchText = ""
    private var trackerFilter: TrackerFilter = .all {
        didSet { reloadTrackers() }
    }

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ru_RU")
        return calendar
    }()

    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ru_RU")
        picker.calendar = calendar
        picker.tintColor = .ypBlack
        picker.frame.size = CGSize(width: 120, height: 34)
        picker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
        return picker
    }()

    private let searchController = UISearchController(searchResultsController: nil)

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 9
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
        layout.headerReferenceSize = CGSize(width: 320, height: 46)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
        collectionView.delaysContentTouches = false
        collectionView.allowsSelection = false
        collectionView.contentInset.bottom = 16
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private let emptyStateView = EmptyStateView(
        imageName: "StubTrackers",
        text: "Что будем отслеживать?"
    )

    private let filterButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Фильтры"
        configuration.baseForegroundColor = .ypBlack
        configuration.background.backgroundColor = .ypBackground
        configuration.background.cornerRadius = 16
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 17)
            return outgoing
        }
        let button = UIButton(configuration: configuration)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var visibleCategories: [TrackerCategory] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return categories.compactMap { category in
            let trackers = category.trackers.filter { tracker in
                let matchesDate = tracker.isScheduled(on: currentDate, calendar: calendar)
                let matchesQuery = query.isEmpty || tracker.name.localizedStandardContains(query)
                let matchesFilter: Bool
                switch trackerFilter {
                case .all, .today:
                    matchesFilter = true
                case .completed:
                    matchesFilter = completedTrackerIds.contains(tracker.id)
                case .uncompleted:
                    matchesFilter = !completedTrackerIds.contains(tracker.id)
                }
                return matchesDate && matchesQuery && matchesFilter
            }
            guard !trackers.isEmpty else { return nil }
            return TrackerCategory(title: category.title, trackers: trackers)
        }
    }

    private var hasTrackersForSelectedDate: Bool {
        categories.contains { category in
            category.trackers.contains { $0.isScheduled(on: currentDate, calendar: calendar) }
        }
    }

    private var isFutureDate: Bool {
        calendar.startOfDay(for: currentDate) > calendar.startOfDay(for: Date())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        navigationItem.title = "Трекеры"
        navigationItem.largeTitleDisplayMode = .always
        setupNavigationItems()
        setupCollection()
        setupEmptyState()
        setupSearch()
        setupFilterButton()
        restoreStoredTrackers()
        currentDate = datePicker.date
        reloadTrackers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = collectionView.bounds.width
        guard width > 1, abs(width - lastCollectionWidth) > 0.5 else { return }
        lastCollectionWidth = width
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.headerReferenceSize = CGSize(width: width, height: 46)
        }
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func setupNavigationItems() {
        let addImage = UIImage(
            systemName: "plus",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .medium)
        )
        let addButton = UIBarButtonItem(
            image: addImage,
            style: .plain,
            target: self,
            action: #selector(didTapAdd)
        )
        addButton.accessibilityLabel = "Добавить"
        navigationItem.leftBarButtonItem = addButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
    }

    private func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск"
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        let textField = searchController.searchBar.searchTextField
        textField.backgroundColor = .ypBackground
        textField.textColor = .ypBlack
        textField.font = .systemFont(ofSize: 17)
        textField.layer.cornerRadius = 10
        textField.clipsToBounds = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func setupCollection() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            TrackerCell.self,
            forCellWithReuseIdentifier: TrackerCell.reuseIdentifier
        )
        collectionView.register(
            TrackerCategoryHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TrackerCategoryHeaderView.reuseIdentifier
        )
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isUserInteractionEnabled = false
        view.addSubview(emptyStateView)
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func rebuildCompletedTrackerIds() {
        let day = calendar.startOfDay(for: currentDate)
        completedTrackerIds = Set(
            completedTrackers.compactMap { record in
                calendar.isDate(record.date, inSameDayAs: day) ? record.trackerId : nil
            }
        )
    }

    private func reloadTrackers() {
        guard isViewLoaded else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.updatePlaceholder()
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
        }
    }

    private func updatePlaceholder() {
        let isEmpty = visibleCategories.isEmpty
        emptyStateView.isHidden = !isEmpty
        filterButton.isHidden = !hasTrackersForSelectedDate
        collectionView.contentInset.bottom = filterButton.isHidden ? 16 : 82
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = trackerFilter == .completed || trackerFilter == .uncompleted
        if query.isEmpty && !filtered {
            emptyStateView.update(
                imageName: "StubTrackers",
                text: "Что будем отслеживать?",
                rendersAsTemplate: false
            )
        } else {
            emptyStateView.update(
                imageName: "StubSearch",
                text: "Ничего не найдено",
                rendersAsTemplate: true
            )
        }
    }

    private func restoreStoredTrackers() {
        let snapshot = store.load()
        isRestoring = true
        categories = snapshot.categories
        completedTrackers = snapshot.records
        isRestoring = false
    }

    private func persist() {
        guard !isRestoring else { return }
        store.save(categories: categories, records: completedTrackers)
    }

    private func setupFilterButton() {
        filterButton.addTarget(self, action: #selector(filterTapped), for: .touchUpInside)
        view.addSubview(filterButton)
        NSLayoutConstraint.activate([
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filterButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func toggleCompletion(for tracker: Tracker) {
        guard !isFutureDate else { return }
        let day = calendar.startOfDay(for: currentDate)
        if completedTrackerIds.contains(tracker.id) {
            completedTrackers.removeAll { record in
                record.trackerId == tracker.id && calendar.isDate(record.date, inSameDayAs: day)
            }
        } else {
            completedTrackers.append(TrackerRecord(trackerId: tracker.id, date: day))
        }
    }

    private func addTracker(_ tracker: Tracker, toCategory title: String) {
        var updatedCategories: [TrackerCategory] = []
        var inserted = false
        for category in categories {
            if category.title == title {
                updatedCategories.append(
                    TrackerCategory(title: category.title, trackers: category.trackers + [tracker])
                )
                inserted = true
            } else {
                updatedCategories.append(category)
            }
        }
        if !inserted {
            updatedCategories.append(TrackerCategory(title: title, trackers: [tracker]))
        }
        categories = updatedCategories
    }

    @objc private func didTapAdd() {
        let typeViewController = TrackerTypeViewController()
        typeViewController.delegate = self
        let navigation = UINavigationController(rootViewController: typeViewController)
        navigation.modalPresentationStyle = .pageSheet
        navigation.navigationBar.applyTrackerAppearance(usesCompactTitle: true)
        if let sheet = navigation.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(navigation, animated: true)
    }

    @objc private func datePickerChanged() {
        if trackerFilter == .today {
            trackerFilter = .all
        }
        currentDate = datePicker.date
    }

    @objc private func filterTapped() {
        let filtersViewController = FiltersViewController(selected: trackerFilter)
        filtersViewController.delegate = self
        let navigation = UINavigationController(rootViewController: filtersViewController)
        navigation.modalPresentationStyle = .pageSheet
        navigation.navigationBar.applyTrackerAppearance(usesCompactTitle: true)
        if let sheet = navigation.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(navigation, animated: true)
    }
}

extension TrackersViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        visibleCategories.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        visibleCategories[section].trackers.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.reuseIdentifier,
            for: indexPath
        ) as? TrackerCell else {
            return UICollectionViewCell()
        }
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        let completedDays = completedTrackers.filter { $0.trackerId == tracker.id }.count
        let model = TrackerCellModel(
            emoji: tracker.emoji,
            name: tracker.name,
            color: tracker.color,
            daysText: RussianPlural.days(completedDays),
            isCompleted: completedTrackerIds.contains(tracker.id),
            isCompleteButtonEnabled: !isFutureDate
        )
        cell.delegate = self
        cell.configure(with: model)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: TrackerCategoryHeaderView.reuseIdentifier,
            for: indexPath
        ) as? TrackerCategoryHeaderView else {
            return UICollectionReusableView()
        }
        header.configure(title: visibleCategories[indexPath.section].title)
        return header
    }
}

extension TrackersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = collectionView.bounds.width
        guard width > 0 else { return CGSize(width: 160, height: 148) }
        let itemWidth = floor((width - 16 - 16 - 9) / 2)
        return CGSize(width: itemWidth, height: 148)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        let width = collectionView.bounds.width > 1 ? collectionView.bounds.width : view.bounds.width
        return CGSize(width: max(width, 1), height: 46)
    }
}

extension TrackersViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
        reloadTrackers()
    }
}

extension TrackersViewController: TrackerCellDelegate {
    func trackerCellDidTapCompleteButton(_ cell: TrackerCell) {
        guard let indexPath = collectionView.indexPath(for: cell),
              indexPath.section < visibleCategories.count,
              indexPath.item < visibleCategories[indexPath.section].trackers.count else { return }
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        toggleCompletion(for: tracker)
    }
}

extension TrackersViewController: FiltersViewControllerDelegate {
    func filtersViewController(_ viewController: FiltersViewController, didSelect filter: TrackerFilter) {
        if filter == .today {
            let today = Date()
            datePicker.setDate(today, animated: false)
            currentDate = today
        }
        trackerFilter = filter
    }
}

extension TrackersViewController: NewTrackerViewControllerDelegate {
    func categoryTitles() -> [String] {
        categories.map(\.title)
    }

    func addCategory(title: String) {
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 38 else { return }
        guard !categories.contains(where: { $0.title.caseInsensitiveCompare(name) == .orderedSame }) else { return }
        categories = categories + [TrackerCategory(title: name, trackers: [])]
    }

    func newTrackerViewController(
        _ viewController: NewTrackerViewController,
        didCreate tracker: Tracker,
        categoryTitle: String
    ) {
        addTracker(tracker, toCategory: categoryTitle)
    }
}
