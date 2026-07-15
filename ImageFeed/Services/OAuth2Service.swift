import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()

    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?

    private init() {}

    func fetchAuthToken(
        code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        if lastCode == code {
            return
        }

        task?.cancel()
        lastCode = code

        guard let request = makeOAuthTokenRequest(code: code) else {
            DispatchQueue.main.async {
                completion(.failure(OAuth2ServiceError.invalidRequest))
            }
            return
        }

        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            defer {
                self?.task = nil
                self?.lastCode = nil
            }

            if let error {
                print("[OAuth2Service] Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[OAuth2Service] Invalid HTTP response")
                DispatchQueue.main.async {
                    completion(.failure(OAuth2ServiceError.invalidResponse))
                }
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let statusCode = httpResponse.statusCode
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                print("[OAuth2Service] Unsplash error \(statusCode): \(body)")
                DispatchQueue.main.async {
                    completion(.failure(OAuth2ServiceError.httpError(statusCode: statusCode)))
                }
                return
            }

            guard let data else {
                print("[OAuth2Service] Empty response body")
                DispatchQueue.main.async {
                    completion(.failure(OAuth2ServiceError.invalidResponse))
                }
                return
            }

            do {
                let responseBody = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(responseBody.accessToken))
                }
            } catch {
                print("[OAuth2Service] Decoding error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }

        self.task = task
        task.resume()
    }

    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let url = URL(string: Constants.unsplashTokenURLString) else {
            print("[OAuth2Service] Failed to create token URL")
            return nil
        }

        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("[OAuth2Service] Failed to create URLComponents")
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]

        guard let requestURL = urlComponents.url else {
            print("[OAuth2Service] Failed to create URLRequest URL")
            return nil
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        return request
    }
}

enum OAuth2ServiceError: Error {
    case invalidRequest
    case invalidResponse
    case httpError(statusCode: Int)
}
