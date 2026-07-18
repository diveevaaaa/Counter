import Foundation
import SwiftKeychainWrapper

final class OAuth2TokenStorage {
    static let shared = OAuth2TokenStorage()

    private let keychain = KeychainWrapper.standard

    private init() {}

    var token: String? {
        get {
            keychain.string(forKey: Constants.Storage.accessToken)
        }
        set {
            if let newValue {
                keychain.set(newValue, forKey: Constants.Storage.accessToken)
            } else {
                keychain.removeObject(forKey: Constants.Storage.accessToken)
            }
        }
    }

    func clearToken() {
        token = nil
    }
}
