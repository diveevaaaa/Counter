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
                    self.requestNextQuestion()
                    return
                }

                let question = self.makeQuestion(for: rating, image: image)
                self.delegate?.didReceiveNextQuestion(question: question)
            case .failure:
                self.requestNextQuestion()
            }
        }
    }

    func reset() {
        currentQuestionIndex = 0
        movies.shuffle()
    }

    private func makeQuestion(for rating: Float, image: UIImage) -> QuizQuestion {
        let comparison = Bool.random()
            ? RatingComparison.greaterThan
            : RatingComparison.lessThan
        let ratingThreshold = makeRatingThreshold(near: rating, comparison: comparison)

        return QuizQuestion(
            image: image,
            text: "Рейтинг этого фильма \(comparison.questionText) чем \(ratingThreshold)?",
            correctAnswer: comparison.isCorrect(movieRating: rating, threshold: Float(ratingThreshold))
        )
    }

    private func makeRatingThreshold(near rating: Float, comparison: RatingComparison) -> Int {
        let roundedRating = Int(rating.rounded())

        switch comparison {
        case .greaterThan:
            return min(max(roundedRating - Int.random(in: 0...1), 5), 9)
        case .lessThan:
            return min(max(roundedRating + Int.random(in: 0...1), 6), 10)
        }
    }
}

private enum RatingComparison {
    case greaterThan
    case lessThan

    var questionText: String {
        switch self {
        case .greaterThan:
            return "больше"
        case .lessThan:
            return "меньше"
        }
    }

    func isCorrect(movieRating: Float, threshold: Float) -> Bool {
        switch self {
        case .greaterThan:
            return movieRating > threshold
        case .lessThan:
            return movieRating < threshold
        }
    }
}
