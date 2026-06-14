import UIKit

final class MovieQuizViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var questionLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var noButton: UIButton!
    @IBOutlet private var yesButton: UIButton!

    // MARK: - Private properties
    private var currentQuestionIndex = 0
    private let questionsAmount: Int = 10
    private var correctAnswers = 0
    private var currentQuestion: QuizQuestion?
    private let questionFactory: QuestionFactoryProtocol = QuestionFactory()
    private var statisticService: StatisticServiceProtocol = StatisticService()
    private lazy var resultAlertPresenter = ResultAlertPresenter(viewController: self)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInterface()
        showNextQuestion()
    }

    // MARK: - IBActions
    @IBAction private func yesButtonPressed(_ sender: UIButton) {
        handleAnswer(givenAnswer: true)
    }

    @IBAction private func noButtonPressed(_ sender: UIButton) {
        handleAnswer(givenAnswer: false)
    }

    // MARK: - Private methods
    private func setupInterface() {
        view.backgroundColor = UIColor(named: "YPBlack")

        textLabel.text = "Вопрос:"
        textLabel.font = UIFont(name: "YSDisplay-Medium", size: 20)
        textLabel.textColor = UIColor(named: "YPWhite")

        counterLabel.font = UIFont(name: "YSDisplay-Medium", size: 20)
        counterLabel.textColor = UIColor(named: "YPWhite")

        questionLabel.font = UIFont(name: "YSDisplay-Bold", size: 23)
        questionLabel.textColor = UIColor(named: "YPWhite")

        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true

        configureButton(noButton, title: "Нет")
        configureButton(yesButton, title: "Да")
    }

    private func configureButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
        button.setTitleColor(UIColor(named: "YPBlack"), for: .normal)
        button.backgroundColor = UIColor(named: "YPWhite")
        button.layer.cornerRadius = 15
        button.layer.masksToBounds = true
    }

    private func showNextQuestion() {
        guard let question = questionFactory.requestNextQuestion() else { return }
        currentQuestion = question
        let viewModel = convert(model: question)
        show(quiz: viewModel)
    }

    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }

    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        questionLabel.text = step.question
        counterLabel.text = step.questionNumber
    }

    private func handleAnswer(givenAnswer: Bool) {
        guard let currentQuestion else { return }
        let isCorrect = givenAnswer == currentQuestion.correctAnswer
        showAnswerResult(isCorrect: isCorrect)
    }

    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }

        yesButton.isEnabled = false
        noButton.isEnabled = false

        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect
            ? UIColor(named: "YPGreen")?.cgColor
            : UIColor(named: "YPRed")?.cgColor

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.yesButton.isEnabled = true
            self.noButton.isEnabled = true
            self.showNextQuestionOrResults()
        }
    }

    private func showNextQuestionOrResults() {
        imageView.layer.borderWidth = 0

        if currentQuestionIndex == questionsAmount - 1 {
            showFinalResults()
        } else {
            currentQuestionIndex += 1
            showNextQuestion()
        }
    }

    private func showFinalResults() {
        statisticService.store(correct: correctAnswers, total: questionsAmount)

        let result = makeResultsViewModel()
        let alertModel = AlertModel(
            title: result.title,
            message: result.text,
            buttonText: result.buttonText
        ) { [weak self] in
            self?.restartQuiz()
        }
        resultAlertPresenter.showAlert(model: alertModel)
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

    private func restartQuiz() {
        currentQuestionIndex = 0
        correctAnswers = 0
        currentQuestion = nil
        questionFactory.reset()
        showNextQuestion()
    }
}
