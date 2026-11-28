import Foundation

enum CatalogSort {
    case name
    case nftCount
}

struct CatalogCellModel {
    let title: String
    let countText: String
    let coverURL: URL?
}

final class CatalogViewModel {
    var onChange: (() -> Void)?
    var onError: ((String) -> Void)?

    private(set) var cells: [CatalogCellModel] = []
    private(set) var isLoading = false

    private let client: NetworkClient
    private var collections: [NFTCollection] = []
    private var sort: CatalogSort = .name
    private var loadGeneration = 0

    init(client: NetworkClient = NetworkClient()) {
        self.client = client
    }

    func load() {
        loadGeneration += 1
        let generation = loadGeneration
        isLoading = true
        onChange?()
        client.fetchCollections { [weak self] result in
            guard let self, generation == self.loadGeneration else { return }
            self.isLoading = false
            switch result {
            case .success(let collections):
                self.collections = collections
                self.applySort()
            case .failure:
                self.cells = []
                self.onChange?()
                self.onError?("Не удалось загрузить данные")
            }
        }
    }

    func sort(by sort: CatalogSort) {
        self.sort = sort
        applySort()
    }

    private func applySort() {
        let sorted: [NFTCollection]
        switch sort {
        case .name:
            sorted = collections.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .nftCount:
            sorted = collections.sorted { $0.nfts.count > $1.nfts.count }
        }
        cells = sorted.map { collection in
            CatalogCellModel(
                title: collection.name,
                countText: "\(collection.nfts.count) NFT",
                coverURL: URL(string: collection.cover)
            )
        }
        onChange?()
    }
}
