import Foundation

protocol MoviesLoading {
    func loadMovies(handler: @escaping (Result<[Movie], Error>) -> Void)
    func loadImageData(from url: URL, handler: @escaping (Result<Data, Error>) -> Void)
}

final class MoviesLoader: MoviesLoading {
    private enum Endpoint {
        private static let apiKey = "k_zcuw1ytf"
        private static let baseURL = "https://tv-api.com/en/API"

        static let top250Movies = URL(string: "\(baseURL)/Top250Movies/\(apiKey)")!
        static let mostPopularMovies = URL(string: "\(baseURL)/MostPopularMovies/\(apiKey)")!
    }

    private let networkClient: NetworkRouting
    private let decoder = JSONDecoder()

    init(networkClient: NetworkRouting = NetworkClient()) {
        self.networkClient = networkClient
    }

    func loadMovies(handler: @escaping (Result<[Movie], Error>) -> Void) {
        let endpoints = [
            Endpoint.top250Movies,
            Endpoint.mostPopularMovies
        ]
        let dispatchGroup = DispatchGroup()
        let lock = NSLock()
        var loadedMovies: [Movie] = []
        var receivedError: Error?

        endpoints.forEach { url in
            dispatchGroup.enter()

            networkClient.fetch(url: url) { [weak self] result in
                defer { dispatchGroup.leave() }

                guard let self else { return }

                switch result {
                case .success(let data):
                    do {
                        let response = try self.decoder.decode(MoviesResponse.self, from: data)

                        if response.errorMessage.isEmpty {
                            lock.lock()
                            loadedMovies.append(contentsOf: response.items)
                            lock.unlock()
                        } else {
                            lock.lock()
                            receivedError = NetworkError.apiError(response.errorMessage)
                            lock.unlock()
                        }
                    } catch {
                        lock.lock()
                        receivedError = error
                        lock.unlock()
                    }
                case .failure(let error):
                    lock.lock()
                    receivedError = error
                    lock.unlock()
                }
            }
        }

        dispatchGroup.notify(queue: .global()) {
            lock.lock()
            let movies = loadedMovies
            let error = receivedError
            lock.unlock()

            if let error {
                handler(.failure(error))
                return
            }

            let uniqueMovies = self.uniqueMovies(from: movies)
                .filter { $0.rating != nil && $0.imageURL != nil }

            guard !uniqueMovies.isEmpty else {
                handler(.failure(NetworkError.noMoviesAvailable))
                return
            }

            handler(.success(uniqueMovies))
        }
    }

    func loadImageData(from url: URL, handler: @escaping (Result<Data, Error>) -> Void) {
        networkClient.fetch(url: url, handler: handler)
    }

    private func uniqueMovies(from movies: [Movie]) -> [Movie] {
        var seenIDs = Set<String>()

        return movies.filter { movie in
            seenIDs.insert(movie.id).inserted
        }
    }
}
