import UIKit

protocol QuestionFactoryDelegate: AnyObject {
    func didLoadDataFromServer()
    func didFailToLoadData(with error: Error)
    func didReceiveNextQuestion(question: QuizQuestion?)
}

protocol QuestionFactoryProtocol {
    var delegate: QuestionFactoryDelegate? { get set }

    func loadData()
    func requestNextQuestion()
    func reset()
}

final class QuestionFactory: QuestionFactoryProtocol {
    weak var delegate: QuestionFactoryDelegate?

    private var currentQuestionIndex = 0
    private var movies: [Movie] = []
    private let moviesLoader: MoviesLoading

    init(moviesLoader: MoviesLoading = MoviesLoader()) {
        self.moviesLoader = moviesLoader
    }

    func loadData() {
        moviesLoader.loadMovies { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let movies):
                self.movies = movies.shuffled()
                self.delegate?.didLoadDataFromServer()
            case .failure(let error):
                self.delegate?.didFailToLoadData(with: error)
            }
        }
    }

    func requestNextQuestion() {
        guard let movie = movies[safe: currentQuestionIndex],
              let rating = movie.rating,
              let imageURL = movie.imageURL else {
            delegate?.didReceiveNextQuestion(question: nil)
            return
        }

        currentQuestionIndex += 1
        moviesLoader.loadImageData(from: imageURL) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let data):
                guard let image = UIImage(data: data) else {
                    self.delegate?.didFailToLoadData(with: NetworkError.imageDataConversionFailed)
                    return
                }

                let ratingThreshold = Int.random(in: 6...8)
                let question = QuizQuestion(
                    image: image,
                    text: "Рейтинг этого фильма больше чем \(ratingThreshold)?",
                    correctAnswer: rating > Float(ratingThreshold)
                )
                self.delegate?.didReceiveNextQuestion(question: question)
            case .failure(let error):
                self.delegate?.didFailToLoadData(with: error)
            }
        }
    }

    func reset() {
        currentQuestionIndex = 0
        movies.shuffle()
    }
}
