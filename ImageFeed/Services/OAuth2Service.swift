import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()

    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?

    private init() {}

    func fetchOAuthToken(
        code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        assert(Thread.isMainThread)

        if lastCode == code {
            print("[fetchOAuthToken]: duplicate request with code \(code)")
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        task?.cancel()
        lastCode = code

        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[fetchOAuthToken]: failed to create request for code \(code)")
            completion(.failure(NetworkError.invalidRequest))
            lastCode = nil
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            defer {
                self?.task = nil
                self?.lastCode = nil
            }

            switch result {
            case .success(let responseBody):
                completion(.success(responseBody.accessToken))
            case .failure(let error):
                print("[fetchOAuthToken]: failure for code \(code), error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        self.task = task
        task.resume()
    }

    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let url = URL(string: Constants.unsplashTokenURLString) else {
            print("[fetchOAuthToken]: failed to create token URL")
            return nil
        }

        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("[fetchOAuthToken]: failed to create URLComponents")
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: Constants.API.authorizationCode)
        ]

        guard let requestURL = urlComponents.url else {
            print("[fetchOAuthToken]: failed to create request URL")
            return nil
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        return request
    }
}
