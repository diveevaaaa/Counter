import Foundation

final class ProfileImageService {
    static let shared = ProfileImageService()

    static let didChangeNotification = Notification.Name(Constants.Notifications.profileImageServiceDidChange)

    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage.shared
    private var task: URLSessionTask?
    private(set) var avatarURL: String?

    private init() {}

    func clearProfileImage() {
        avatarURL = nil
    }

    func fetchProfileImageURL(
        username: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        assert(Thread.isMainThread)

        task?.cancel()

        guard let request = makeProfileImageRequest(username: username) else {
            print("[fetchProfileImageURL]: failed to create request for username \(username)")
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            defer {
                self?.task = nil
            }

            switch result {
            case .success(let userResult):
                guard let profileImageURL = userResult.profileImage?.medium else {
                    print("[fetchProfileImageURL]: missing profile image URL for username \(username)")
                    completion(.failure(NetworkError.urlSessionError))
                    return
                }

                self?.avatarURL = profileImageURL
                completion(.success(profileImageURL))
                NotificationCenter.default.post(
                    name: Self.didChangeNotification,
                    object: self,
                    userInfo: ["URL": profileImageURL]
                )
            case .failure(let error):
                print("[fetchProfileImageURL]: failure for username \(username), error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        self.task = task
        task.resume()
    }

    private func makeProfileImageRequest(username: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: Constants.defaultBaseURLString) else {
            print("[fetchProfileImageURL]: failed to create URLComponents")
            return nil
        }

        urlComponents.path = Constants.API.usersPath + "/" + username

        guard let url = urlComponents.url else {
            print("[fetchProfileImageURL]: failed to create URL")
            return nil
        }

        guard let token = tokenStorage.token else {
            print("[fetchProfileImageURL]: missing bearer token")
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue(Constants.API.bearer + token, forHTTPHeaderField: Constants.API.authorizationHeader)
        return request
    }
}
