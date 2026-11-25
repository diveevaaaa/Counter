import UIKit

final class TrackersViewController: UIViewController {
    private let usesPersistentStore: Bool
    private lazy var categoryStore = TrackerCategoryStore()
    private lazy var trackerStore = TrackerStore(categoryStore: categoryStore)
    private lazy var recordStore = TrackerRecordStore(trackerStore: trackerStore)

    var categories: [TrackerCategory] = [] {
        didSet {
            reloadTrackers()
        }
    }

    var completedTrackers: [TrackerRecord] = [] {
        didSet {
            rebuildCompletedTrackerIds()
            reloadTrackers()
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
        calendar.locale = Locale.current
        return calendar
    }()

    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale.current
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
        let button = UIButton(configuration: .plain())
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var isFilterActive: Bool {
        trackerFilter == .completed || trackerFilter == .uncompleted
    }

    private var visibleCategories: [TrackerCategory] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        var regular: [TrackerCategory] = []
        var pinned: [Tracker] = []
        for category in categories {
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
            pinned.append(contentsOf: trackers.filter(\.isPinned))
            let unpinned = trackers.filter { !$0.isPinned }
            if !unpinned.isEmpty {
                regular.append(TrackerCategory(title: category.title, trackers: unpinned))
            }
        }
        if pinned.isEmpty {
            return regular
        }
        return [TrackerCategory(title: L10n.text("pinned.title"), trackers: pinned)] + regular
    }

    private var hasTrackersForSelectedDate: Bool {
        categories.contains { category in
            category.trackers.contains { $0.isScheduled(on: currentDate, calendar: calendar) }
        }
    }

    private var isFutureDate: Bool {
        calendar.startOfDay(for: currentDate) > calendar.startOfDay(for: Date())
    }

    init(usesPersistentStore: Bool = true) {
        self.usesPersistentStore = usesPersistentStore
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypWhite
        navigationItem.title = L10n.text("trackers.title")
        navigationItem.largeTitleDisplayMode = .always
        setupNavigationItems()
        setupCollection()
        setupEmptyState()
        setupSearch()
        setupFilterButton()
        datePicker.date = currentDate
        if usesPersistentStore {
            categoryStore.delegate = self
            trackerStore.delegate = self
            recordStore.delegate = self
            applyStoreSnapshot()
        }
        reloadTrackers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsService.report(.open)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        AnalyticsService.report(.close)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFilterButton()
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
        addButton.accessibilityLabel = L10n.text("trackers.add")
        navigationItem.leftBarButtonItem = addButton
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
    }

    private func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = L10n.text("trackers.search")
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
        let bottomInset: CGFloat = filterButton.isHidden ? 16 : 90
        collectionView.contentInset.bottom = bottomInset
        collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
        updateFilterButton()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let showsFilteredEmptyState = !query.isEmpty || trackerFilter != .all
        if !showsFilteredEmptyState {
            emptyStateView.update(
                imageName: "StubTrackers",
                text: L10n.text("trackers.empty"),
                rendersAsTemplate: false
            )
        } else {
            emptyStateView.update(
                imageName: "StubSearch",
                text: L10n.text("trackers.emptySearch"),
                rendersAsTemplate: true
            )
        }
    }

    private func applyStoreSnapshot() {
        categories = categoryStore.categories()
        completedTrackers = recordStore.records()
    }

    private func setupFilterButton() {
        updateFilterButton()
        filterButton.addTarget(self, action: #selector(filterTapped), for: .touchUpInside)
        view.addSubview(filterButton)
        NSLayoutConstraint.activate([
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filterButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func updateFilterButton() {
        var configuration = UIButton.Configuration.plain()
        configuration.title = L10n.text("trackers.filters")
        configuration.baseForegroundColor = isFilterActive ? .ypRed : .white
        configuration.background.backgroundColor = .ypBlue
        configuration.background.cornerRadius = 16
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 17, weight: .regular)
            return outgoing
        }
        filterButton.configuration = configuration
    }

    private func categoryTitle(containing trackerId: UUID) -> String {
        categories.first { category in
            category.trackers.contains { $0.id == trackerId }
        }?.title ?? ""
    }

    private func editTracker(_ tracker: Tracker) {
        let type: TrackerCreationType
        switch tracker.schedule {
        case .habit:
            type = .habit
        case .irregular:
            type = .irregularEvent
        }
        let editor = NewTrackerViewController(
            type: type,
            tracker: tracker,
            categoryTitle: categoryTitle(containing: tracker.id)
        )
        editor.delegate = self
        presentCreation(editor)
    }

    private func confirmDelete(_ tracker: Tracker) {
        let alert = UIAlertController(
            title: L10n.text("delete.message"),
            message: nil,
            preferredStyle: .actionSheet
        )
        let remove = UIAlertAction(title: L10n.text("delete.confirm"), style: .destructive) { [weak self] _ in
            self?.trackerStore.delete(id: tracker.id)
        }
        alert.addAction(remove)
        alert.addAction(UIAlertAction(title: L10n.text("delete.cancel"), style: .cancel))
        present(alert, animated: true)
    }

    private func presentCreation(_ root: UIViewController) {
        let navigation = UINavigationController(rootViewController: root)
        navigation.modalPresentationStyle = .pageSheet
        navigation.navigationBar.applyTrackerAppearance(usesCompactTitle: true)
        if let sheet = navigation.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(navigation, animated: true)
    }

    private func toggleCompletion(for tracker: Tracker) {
        guard !isFutureDate else { return }
        let day = calendar.startOfDay(for: currentDate)
        if completedTrackerIds.contains(tracker.id) {
            recordStore.remove(trackerId: tracker.id, on: day)
        } else {
            recordStore.add(trackerId: tracker.id, on: day)
        }
    }

    @objc private func didTapAdd() {
        AnalyticsService.report(.click(.addTrack))
        let typeViewController = TrackerTypeViewController()
        typeViewController.delegate = self
        presentCreation(typeViewController)
    }

    @objc private func datePickerChanged() {
        currentDate = datePicker.date
    }

    @objc private func filterTapped() {
        AnalyticsService.report(.click(.filter))
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
            daysText: L10n.days(completedDays),
            isCompleted: completedTrackerIds.contains(tracker.id),
            isCompleteButtonEnabled: !isFutureDate,
            isPinned: tracker.isPinned
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

    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let sections = visibleCategories
        guard sections.indices.contains(indexPath.section) else { return nil }
        let trackers = sections[indexPath.section].trackers
        guard trackers.indices.contains(indexPath.item) else { return nil }
        let tracker = trackers[indexPath.item]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self else { return nil }
            let pinTitle = tracker.isPinned ? L10n.text("menu.unpin") : L10n.text("menu.pin")
            let pin = UIAction(title: pinTitle) { [weak self] _ in
                self?.trackerStore.setPinned(!tracker.isPinned, id: tracker.id)
            }
            let edit = UIAction(title: L10n.text("menu.edit")) { [weak self] _ in
                AnalyticsService.report(.click(.edit))
                self?.editTracker(tracker)
            }
            let delete = UIAction(title: L10n.text("menu.delete"), attributes: .destructive) { [weak self] _ in
                AnalyticsService.report(.click(.delete))
                self?.confirmDelete(tracker)
            }
            return UIMenu(children: [pin, edit, delete])
        }
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
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let sections = visibleCategories
        guard sections.indices.contains(indexPath.section) else { return }
        let trackers = sections[indexPath.section].trackers
        guard trackers.indices.contains(indexPath.item) else { return }
        AnalyticsService.report(.click(.track))
        let tracker = trackers[indexPath.item]
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
    func newTrackerViewController(
        _ viewController: NewTrackerViewController,
        didFinish tracker: Tracker,
        categoryTitle: String
    ) {
        if trackerStore.tracker(id: tracker.id) != nil {
            trackerStore.update(tracker, categoryTitle: categoryTitle)
        } else {
            trackerStore.add(tracker, toCategory: categoryTitle)
        }
    }
}

extension TrackersViewController: TrackerCategoryStoreDelegate {
    func trackerCategoryStoreDidUpdate() {
        applyStoreSnapshot()
    }
}

extension TrackersViewController: TrackerStoreDelegate {
    func trackerStoreDidUpdate() {
        applyStoreSnapshot()
    }
}

extension TrackersViewController: TrackerRecordStoreDelegate {
    func trackerRecordStoreDidUpdate() {
        applyStoreSnapshot()
    }
}
