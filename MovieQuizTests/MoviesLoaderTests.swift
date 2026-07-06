import XCTest
@testable import MovieQuiz

final class MoviesLoaderTests: XCTestCase {
    func testLoadMoviesReturnsMoviesOnSuccess() {
        let networkClient = NetworkClientMock(result: .success(Self.moviesResponseData))
        let loader = MoviesLoader(networkClient: networkClient)
        let expectation = expectation(description: "Wait for successful movies loading")

        loader.loadMovies { result in
            switch result {
            case .success(let movies):
                XCTAssertEqual(movies.count, 1)
                XCTAssertEqual(movies.first?.id, "tt0111161")
                XCTAssertEqual(movies.first?.title, "The Shawshank Redemption")
            case .failure(let error):
                XCTFail("Expected success, got error: \(error)")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testLoadMoviesReturnsErrorOnFailure() {
        let expectedError = NetworkError.urlSessionError
        let networkClient = NetworkClientMock(result: .failure(expectedError))
        let loader = MoviesLoader(networkClient: networkClient)
        let expectation = expectation(description: "Wait for failed movies loading")

        loader.loadMovies { result in
            switch result {
            case .success(let movies):
                XCTFail("Expected failure, got movies: \(movies)")
            case .failure:
                XCTAssertTrue(true)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}

private extension MoviesLoaderTests {
    static let moviesResponseData = """
    {
      "items": [
        {
          "id": "tt0111161",
          "title": "The Shawshank Redemption",
          "image": "https://example.com/poster.jpg",
          "imDbRating": "9.3"
        }
      ],
      "errorMessage": ""
    }
    """.data(using: .utf8)!
}

private final class NetworkClientMock: NetworkRouting {
    private let result: Result<Data, Error>

    init(result: Result<Data, Error>) {
        self.result = result
    }

    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void) {
        handler(result)
    }
}
