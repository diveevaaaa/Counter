import Foundation

final class ImagesListService {
    static let shared = ImagesListService()

    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")

    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage.shared
    private var fetchTask: URLSessionTask?

    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?

    private init() {}

    func clearImagesList() {
        lastLoadedPage = nil
        photos = []
    }

    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)

        guard fetchTask == nil else {
            print("[ImagesListService.fetchPhotosNextPage]: requestAlreadyInProgress")
            return
        }

        let nextPage = (lastLoadedPage ?? 0) + 1

        guard let request = makePhotosRequest(page: nextPage) else {
            print("[ImagesListService.fetchPhotosNextPage]: invalidRequest page=\(nextPage)")
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            defer {
                self?.fetchTask = nil
            }

            guard let self else { return }

            switch result {
            case .success(let photoResults):
                let newPhotos = photoResults.map(Photo.init)
                DispatchQueue.main.async {
                    self.lastLoadedPage = nextPage
                    self.photos.append(contentsOf: newPhotos)
                    NotificationCenter.default.post(
                        name: Self.didChangeNotification,
                        object: self
                    )
                }
            case .failure(let error):
                print("[ImagesListService.fetchPhotosNextPage]: \(type(of: error)) page=\(nextPage), error=\(error.localizedDescription)")
            }
        }

        fetchTask = task
        task.resume()
    }

    func changeLike(
        photoId: String,
        isLike: Bool,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        assert(Thread.isMainThread)

        guard let request = makeLikeRequest(photoId: photoId, isLike: isLike) else {
            print("[ImagesListService.changeLike]: invalidRequest photoId=\(photoId), isLike=\(isLike)")
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        let task = urlSession.data(for: request) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                switch result {
                case .success:
                    guard let index = self.photos.firstIndex(where: { $0.id == photoId }) else {
                        print("[ImagesListService.changeLike]: invalidRequest photoId=\(photoId) not found")
                        completion(.failure(NetworkError.invalidRequest))
                        return
                    }

                    self.photos[index].isLiked = isLike
                    completion(.success(()))
                case .failure(let error):
                    print("[ImagesListService.changeLike]: \(type(of: error)) photoId=\(photoId), isLike=\(isLike), error=\(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }

        task.resume()
    }

    private func makePhotosRequest(page: Int) -> URLRequest? {
        guard var urlComponents = URLComponents(string: Constants.defaultBaseURLString) else {
            print("[ImagesListService.fetchPhotosNextPage]: invalidRequest failed to create URLComponents page=\(page)")
            return nil
        }

        urlComponents.path = Constants.API.photosPath
        urlComponents.queryItems = [
            URLQueryItem(name: Constants.API.pageQuery, value: String(page)),
            URLQueryItem(name: Constants.API.perPageQuery, value: Constants.API.perPageValue)
        ]

        guard let url = urlComponents.url else {
            print("[ImagesListService.fetchPhotosNextPage]: invalidRequest failed to create URL page=\(page)")
            return nil
        }

        guard let token = tokenStorage.token else {
            print("[ImagesListService.fetchPhotosNextPage]: invalidRequest missing bearer token page=\(page)")
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue(Constants.API.bearer + token, forHTTPHeaderField: Constants.API.authorizationHeader)
        return request
    }

    private func makeLikeRequest(photoId: String, isLike: Bool) -> URLRequest? {
        guard var urlComponents = URLComponents(string: Constants.defaultBaseURLString) else {
            print("[ImagesListService.changeLike]: invalidRequest failed to create URLComponents photoId=\(photoId)")
            return nil
        }

        urlComponents.path = Constants.API.photosPath + "/" + photoId + "/like"

        guard let url = urlComponents.url else {
            print("[ImagesListService.changeLike]: invalidRequest failed to create URL photoId=\(photoId)")
            return nil
        }

        guard let token = tokenStorage.token else {
            print("[ImagesListService.changeLike]: invalidRequest missing bearer token photoId=\(photoId)")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = isLike ? Constants.API.postMethod : Constants.API.deleteMethod
        request.setValue(Constants.API.bearer + token, forHTTPHeaderField: Constants.API.authorizationHeader)
        return request
    }
}
