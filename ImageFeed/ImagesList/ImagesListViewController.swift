import UIKit

final class ImagesListViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!

    private let imagesListService = ImagesListService.shared
    private var photos: [Photo] { imagesListService.photos }
    private var imagesListObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        tableView.backgroundColor = .ypBlack
        tableView.separatorStyle = .none

        imagesListObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateTableViewAnimated()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        imagesListService.fetchPhotosNextPage()
    }

    deinit {
        if let imagesListObserver {
            NotificationCenter.default.removeObserver(imagesListObserver)
        }
    }

    private func updateTableViewAnimated() {
        let oldCount = tableView.numberOfRows(inSection: 0)
        let newCount = photos.count

        guard newCount > oldCount else {
            tableView.reloadData()
            return
        }

        let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
        tableView.performBatchUpdates {
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }

    @IBAction private func imageListCellDidTapLike(_ sender: UIButton) {
        guard !UIBlockingProgressHUD.isBlocking else { return }
        guard let cell = sender.superview?.superview as? ImagesListCell,
              let indexPath = tableView.indexPath(for: cell) else { return }

        let photo = photos[indexPath.row]
        let isLike = !photo.isLiked

        UIBlockingProgressHUD.show()
        imagesListService.changeLike(photoId: photo.id, isLike: isLike) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self else { return }

            switch result {
            case .success:
                cell.setIsLiked(isLike)
            case .failure:
                break
            }
        }
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        ) as? ImagesListCell else {
            return UITableViewCell()
        }

        let photo = photos[indexPath.row]
        cell.configure(with: photo)
        return cell
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        performSegue(withIdentifier: "ShowSingleImage", sender: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == photos.count {
            imagesListService.fetchPhotosNextPage()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            segue.identifier == "ShowSingleImage",
            let viewController = segue.destination as? SingleImageViewController,
            let indexPath = sender as? IndexPath
        else { return }

        let photo = photos[indexPath.row]
        viewController.largeImageURL = URL(string: photo.largeImageURL)
    }
}
