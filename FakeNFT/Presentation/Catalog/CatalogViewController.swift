import UIKit

final class CatalogViewController: UIViewController {
    private let viewModel: CatalogViewModel
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loader = UIActivityIndicatorView(style: .large)

    init(viewModel: CatalogViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = "Каталог"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down"),
            style: .plain,
            target: self,
            action: #selector(sortTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = UIColor(red: 26 / 255, green: 27 / 255, blue: 34 / 255, alpha: 1)
        navigationController?.navigationBar.prefersLargeTitles = true

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 190
        tableView.contentInset.top = 8
        tableView.register(CatalogCell.self, forCellReuseIdentifier: CatalogCell.reuseIdentifier)
        view.addSubview(tableView)

        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.hidesWhenStopped = true
        view.addSubview(loader)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        viewModel.onChange = { [weak self] in
            self?.render()
        }
        viewModel.onError = { [weak self] message in
            self?.showError(message)
        }
        viewModel.load()
    }

    private func render() {
        tableView.reloadData()
        tableView.isUserInteractionEnabled = !viewModel.isLoading
        if viewModel.isLoading {
            loader.startAnimating()
        } else {
            loader.stopAnimating()
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            self?.viewModel.load()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func sortTapped() {
        let sheet = UIAlertController(title: "Сортировка", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "По названию", style: .default) { [weak self] _ in
            self?.viewModel.sort(by: .name)
        })
        sheet.addAction(UIAlertAction(title: "По количеству NFT", style: .default) { [weak self] _ in
            self?.viewModel.sort(by: .nftCount)
        })
        sheet.addAction(UIAlertAction(title: "Закрыть", style: .cancel))
        present(sheet, animated: true)
    }
}

extension CatalogViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.cells.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CatalogCell.reuseIdentifier,
            for: indexPath
        ) as? CatalogCell else {
            return UITableViewCell()
        }
        cell.configure(viewModel.cells[indexPath.row])
        return cell
    }
}
