import XCTest
@testable import MovieQuiz

final class MovieQuizPresenterTests: XCTestCase {
    func testConvertQuizQuestionToQuizStepViewModel() {
        let viewController = MovieQuizViewControllerMock()
        let questionFactory = QuestionFactoryMock()
        let presenter = MovieQuizPresenter(
            viewController: viewController,
            questionFactory: questionFactory,
            statisticService: StatisticServiceMock()
        )
        let imageData = Data([0, 1, 2])
        let question = QuizQuestion(
            imageData: imageData,
            text: "Рейтинг этого фильма больше чем 7?",
            correctAnswer: true
        )

        let viewModel = presenter.convert(model: question)

        XCTAssertEqual(viewModel.imageData, imageData)
        XCTAssertEqual(viewModel.question, "Рейтинг этого фильма больше чем 7?")
        XCTAssertEqual(viewModel.questionNumber, "1/10")
    }
}

private final class MovieQuizViewControllerMock: MovieQuizViewControllerProtocol {
    func showLoadingIndicator() {}
    func hideLoadingIndicator() {}
    func show(quiz step: QuizStepViewModel) {}
    func showQuizResult(isCorrect: Bool) {}
    func show(quiz result: QuizResultsViewModel) {}
    func showNetworkError(message: String) {}
}

private final class QuestionFactoryMock: QuestionFactoryProtocol {
    weak var delegate: QuestionFactoryDelegate?

    func loadData() {}
    func requestNextQuestion() {}
    func reset() {}
}

private final class StatisticServiceMock: StatisticServiceProtocol {
    var gamesCount: Int { 0 }
    var bestGame: GameResult { GameResult(correct: 0, total: 0, date: Date()) }
    var totalAccuracy: Double { 0 }

    func store(correct count: Int, total amount: Int) {}
}
