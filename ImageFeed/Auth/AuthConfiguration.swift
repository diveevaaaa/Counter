import Foundation

struct AuthConfiguration {
    let authorizeURLString: String
    let tokenURLString: String
    let redirectURI: String
    let accessScope: String
    let authNativePath: String

    static let standard = AuthConfiguration(
        authorizeURLString: Constants.unsplashAuthorizeURLString,
        tokenURLString: Constants.unsplashTokenURLString,
        redirectURI: Constants.redirectURI,
        accessScope: Constants.accessScope,
        authNativePath: Constants.authNativePath
    )
}
