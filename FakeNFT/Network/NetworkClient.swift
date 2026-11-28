import Foundation

enum NetworkError: Error {
    case invalidResponse
    case httpStatus(Int)
    case emptyData
}

final class NetworkClient {
    private let session: URLSession
    private let decoderQueue = DispatchQueue(label: "ru.practicum.FakeNFT.decoder", qos: .userInitiated)

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCollections(completion: @escaping (Result<[NFTCollection], Error>) -> Void) {
        let url = APIConfig.baseURL.appendingPathComponent("collections")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if !APIConfig.token.isEmpty {
            request.setValue(APIConfig.token, forHTTPHeaderField: "X-Practicum-Mobile-Token")
        }

        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            if let error {
                self.finish(.failure(error), completion)
                return
            }
            guard let http = response as? HTTPURLResponse else {
                self.finish(.failure(NetworkError.invalidResponse), completion)
                return
            }
            guard (200...299).contains(http.statusCode) else {
                self.finish(.failure(NetworkError.httpStatus(http.statusCode)), completion)
                return
            }
            guard let data, !data.isEmpty else {
                self.finish(.failure(NetworkError.emptyData), completion)
                return
            }
            self.decoderQueue.async { [weak self] in
                guard let self else { return }
                do {
                    let collections = try JSONDecoder().decode([NFTCollection].self, from: data)
                    self.finish(.success(collections), completion)
                } catch {
                    self.finish(.failure(error), completion)
                }
            }
        }.resume()
    }

    private func finish<T>(
        _ result: Result<T, Error>,
        _ completion: @escaping (Result<T, Error>) -> Void
    ) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
}
