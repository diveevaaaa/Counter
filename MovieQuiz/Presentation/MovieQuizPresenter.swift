import Foundation

protocol MovieQuizViewControllerProtocol: AnyObject {
    func showLoadingIndicator()
    func hideLoadingIndicator()
    func show(quiz step: QuizStepViewModel)
    func showQuizResult(isCorrect: Bool)
    func show(quiz result: QuizResultsViewModel)
    func showNetworkError(message: String)
}

final class MovieQuizPresenter {
    private weak var viewController: MovieQuizViewControllerProtocol?
    private var questionFactory: QuestionFactoryProtocol
    private var statisticService: StatisticServiceProtocol
    private var currentQuestionIndex = 0
    private let questionsAmount: Int
    private var correctAnswers = 0
    private var currentQuestion: QuizQuestion?
    private let answerDisplayDelay: TimeInterval

    init(
        viewController: MovieQuizViewControllerProtocol,
        questionFactory: QuestionFactoryProtocol = QuestionFactory(),
        statisticService: StatisticServiceProtocol = StatisticService(),
        questionsAmount: Int = 10,
        answerDisplayDelay: TimeInterval = 1.0
    ) {
        self.viewController = viewController
        self.questionFactory = questionFactory
        self.statisticService = statisticService
        self.questionsAmount = questionsAmount
        self.answerDisplayDelay = answerDisplayDelay
        self.questionFactory.delegate = self
    }

    func viewDidLoad() {
        viewController?.showLoadingIndicator()
        questionFactory.loadData()
    }

    func yesButtonClicked() {
        handleAnswer(givenAnswer: true)
    }

    func noButtonClicked() {
        handleAnswer(givenAnswer: false)
    }

    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        currentQuestion = nil
        questionFactory.reset()
        showNextQuestion()
    }

    func retryLoading() {
        currentQuestionIndex = 0
        correctAnswers = 0
        currentQuestion = nil
        questionFactory.reset()
        viewController?.showLoadingIndicator()
        questionFactory.loadData()
    }

    func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            imageData: model.imageData,
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }

    private func showNextQuestion() {
        viewController?.showLoadingIndicator()
        questionFactory.requestNextQuestion()
    }

    private func handleAnswer(givenAnswer: Bool) {
        guard let currentQuestion else { return }

        let isCorrect = givenAnswer == currentQuestion.correctAnswer
        if isCorrect {
            correctAnswers += 1
        }

        viewController?.showQuizResult(isCorrect: isCorrect)

        DispatchQueue.main.asyncAfter(deadline: .now() + answerDisplayDelay) { [weak self] in
            self?.showNextQuestionOrResults()
        }
    }

    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
            showFinalResults()
        } else {
            currentQuestionIndex += 1
            showNextQuestion()
        }
    }

    private func showFinalResults() {
        statisticService.store(correct: correctAnswers, total: questionsAmount)
        viewController?.show(quiz: makeResultsViewModel())
    }

    private func makeResultsViewModel() -> QuizResultsViewModel {
        let bestGame = statisticService.bestGame
        let message = """
        Ваш результат: \(correctAnswers)/\(questionsAmount)
        Количество сыгранных квизов: \(statisticService.gamesCount)
        Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))
        Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
        """

        return QuizResultsViewModel(
            title: "Этот раунд окончен!",
            text: message,
            buttonText: "Сыграть ещё раз"
        )
    }
}

extension MovieQuizPresenter: QuestionFactoryDelegate {
    func didLoadDataFromServer() {
        DispatchQueue.main.async { [weak self] in
            self?.showNextQuestion()
        }
    }

    func didFailToLoadData(with error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.showNetworkError(message: "Не удалось загрузить данные. Попробуйте ещё раз.")
        }
    }

    func didReceiveNextQuestion(question: QuizQuestion?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.viewController?.hideLoadingIndicator()

            guard let question else {
                self.viewController?.showNetworkError(message: "Не удалось загрузить данные. Попробуйте ещё раз.")
                return
            }

            self.currentQuestion = question
            self.viewController?.show(quiz: self.convert(model: question))
        }
    }
}
