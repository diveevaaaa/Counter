import Foundation

enum Constants {
    static let accessKey = "INSERT_YOUR_UNSPLASH_ACCESS_KEY"
    static let secretKey = "INSERT_YOUR_UNSPLASH_SECRET_KEY"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public+read_user+write_likes"
    static let defaultBaseURLString = "https://api.unsplash.com"

    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
    static let unsplashTokenURLString = "https://unsplash.com/oauth/token"
    static let authNativePath = "/oauth/authorize/native"
    static let bearerTokenStorageKey = "bearerToken"
}
