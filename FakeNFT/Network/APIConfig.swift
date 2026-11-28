import Foundation

enum APIConfig {
    static let baseURL = URL(string: "https://d5dn3j2ouj72b0ejucbl.apigw.yandexcloud.net/api/v1")!

    /// Токен команды из стартового проекта Практикума.
    /// Сервер принимает его в заголовке X-Practicum-Mobile-Token.
    static let token = ""
}
