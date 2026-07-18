import Foundation

enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case invalidRequest
}

extension URLSession {
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        let task = data(for: request) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                do {
                    let decodedObject = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {
                    let dataString = String(data: data, encoding: .utf8) ?? ""
                    print("[objectTask]: DecodingError \(error.localizedDescription), data: \(dataString)")
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }

        return task
    }

    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {
        let fulfillCompletionOnMainThread: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }

        let task = dataTask(with: request) { data, response, error in
            if let data, let response, let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if (200..<300).contains(statusCode) {
                    fulfillCompletionOnMainThread(.success(data))
                } else {
                    let body = String(data: data, encoding: .utf8) ?? ""
                    print("[dataTask]: NetworkError - код ошибки \(statusCode), data: \(body)")
                    fulfillCompletionOnMainThread(.failure(NetworkError.httpStatusCode(statusCode)))
                }
                return
            }

            if let error {
                let nsError = error as NSError
                if nsError.code == NSURLErrorCancelled {
                    print("[dataTask]: request cancelled")
                    return
                }
                print("[dataTask]: urlRequestError \(error.localizedDescription)")
                fulfillCompletionOnMainThread(.failure(NetworkError.urlRequestError(error)))
                return
            }

            print("[dataTask]: urlSessionError")
            fulfillCompletionOnMainThread(.failure(NetworkError.urlSessionError))
        }

        return task
    }
}
