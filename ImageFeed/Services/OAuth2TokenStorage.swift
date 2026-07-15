import Foundation

final class OAuth2TokenStorage {
    static let shared = OAuth2TokenStorage()

    private let userDefaults = UserDefaults.standard

    private init() {}

    var token: String? {
        get {
            userDefaults.string(forKey: Constants.bearerTokenStorageKey)
        }
        set {
            if let newValue {
                userDefaults.set(newValue, forKey: Constants.bearerTokenStorageKey)
            } else {
                userDefaults.removeObject(forKey: Constants.bearerTokenStorageKey)
            }
        }
    }

    func clearToken() {
        token = nil
    }
}
