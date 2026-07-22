import Foundation

protocol AuthHelperProtocol {
    func authRequest() -> URLRequest?
    func code(from url: URL) -> String?
}

final class AuthHelper: AuthHelperProtocol {
    private let configuration: AuthConfiguration

    init(configuration: AuthConfiguration = .standard) {
        self.configuration = configuration
    }

    func authRequest() -> URLRequest? {
        guard let url = authURL() else {
            return nil
        }
        return URLRequest(url: url)
    }

    func authURL() -> URL? {
        guard var urlComponents = URLComponents(string: configuration.authorizeURLString) else {
            print("[AuthHelper] Failed to create URLComponents for authorize URL")
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: configuration.accessScope)
        ]

        guard let url = urlComponents.url else {
            print("[AuthHelper] Failed to create authorize URL")
            return nil
        }

        return url
    }

    func code(from url: URL) -> String? {
        guard let urlComponents = URLComponents(string: url.absoluteString) else {
            print("[AuthHelper] Failed to create URLComponents from redirect URL")
            return nil
        }

        guard urlComponents.path == configuration.authNativePath else {
            return nil
        }

        guard let items = urlComponents.queryItems else {
            print("[AuthHelper] Failed to get query items from redirect URL")
            return nil
        }

        guard let codeItem = items.first(where: { $0.name == "code" }) else {
            return nil
        }

        return codeItem.value
    }
}
