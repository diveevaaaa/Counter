import Foundation

final class ProfileService {
    static let shared = ProfileService()

    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private(set) var profile: Profile?

    private init() {}

    func clearProfile() {
        profile = nil
    }

    func setProfile(_ profile: Profile) {
        self.profile = profile
    }

    func fetchProfile(token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)

        task?.cancel()

        guard let request = makeProfileRequest(token: token) else {
            print("[fetchProfile]: failed to create request")
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            defer {
                self?.task = nil
            }

            switch result {
            case .success(let profileResult):
                let profile = Profile(from: profileResult)
                self?.profile = profile
                completion(.success(profile))
            case .failure(let error):
                print("[fetchProfile]: failure for token, error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        self.task = task
        task.resume()
    }

    private func makeProfileRequest(token: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: Constants.defaultBaseURLString) else {
            print("[fetchProfile]: failed to create URLComponents")
            return nil
        }

        urlComponents.path = Constants.API.mePath

        guard let url = urlComponents.url else {
            print("[fetchProfile]: failed to create URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue(Constants.API.bearer + token, forHTTPHeaderField: Constants.API.authorizationHeader)
        return request
    }
}
