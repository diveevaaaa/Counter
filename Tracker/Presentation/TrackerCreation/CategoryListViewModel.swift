import Foundation

struct CategoryCellModel {
    let title: String
    let isSelected: Bool
    let showsSeparator: Bool
}

final class CategoryListViewModel {
    var onChange: (() -> Void)?
    var onSelect: ((String) -> Void)?

    private let store: TrackerCategoryStore
    private var titles: [String] = []
    private var selectedTitle: String?

    init(store: TrackerCategoryStore = TrackerCategoryStore(), selectedTitle: String?) {
        self.store = store
        self.selectedTitle = selectedTitle
    }

    var isEmpty: Bool {
        titles.isEmpty
    }

    func load() {
        titles = store.fetchCategoryTitles()
        onChange?()
    }

    func numberOfRows() -> Int {
        titles.count
    }

    func cellModel(at index: Int) -> CategoryCellModel {
        let title = titles[index]
        return CategoryCellModel(
            title: title,
            isSelected: title == selectedTitle,
            showsSeparator: index < titles.count - 1
        )
    }

    func select(at index: Int) {
        guard titles.indices.contains(index) else { return }
        let title = titles[index]
        selectedTitle = title
        onChange?()
        onSelect?(title)
    }

    func add(title: String) {
        store.saveCategory(title: title)
        titles = store.fetchCategoryTitles()
        onChange?()
    }
}
