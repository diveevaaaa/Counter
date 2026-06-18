import Foundation

enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case apiError(String)
    case imageDataConversionFailed
}

protocol NetworkRouting {
    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void)
}

final class NetworkClient: NetworkRouting {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("MovieQuiz/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        session.dataTask(with: request) { data, response, error in
            if let error {
                handler(.failure(NetworkError.urlRequestError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                handler(.failure(NetworkError.urlSessionError))
                return
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                handler(.failure(NetworkError.httpStatusCode(httpResponse.statusCode)))
                return
            }

            guard let data else {
                handler(.failure(NetworkError.urlSessionError))
                return
            }

            handler(.success(data))
        }.resume()
    }
}
