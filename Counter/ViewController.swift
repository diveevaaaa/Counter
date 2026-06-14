import UIKit

final class MovieQuizViewController: UIViewController {
    private let questionsAmount = 10
    private let imageBorderWidth: CGFloat = 8

    private lazy var questionFactory: QuestionFactoryProtocol = QuestionFactory(delegate: self)
    private lazy var resultAlertPresenter = ResultAlertPresenter(viewController: self)
    private var statisticService: StatisticServiceProtocol = StatisticService()

    private var currentQuestion: QuizQuestion?
    private var currentQuestionIndex = 0
    private var correctAnswers = 0

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 0
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let questionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 23, weight: .bold)
        label.textColor = .ypWhite
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let counterLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .ypWhite
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var yesButton: UIButton = makeAnswerButton(title: "Да")
    private lazy var noButton: UIButton = makeAnswerButton(title: "Нет")

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        questionFactory.requestNextQuestion()
    }

    @objc private func yesButtonTapped() {
        checkAnswer(true)
    }

    @objc private func noButtonTapped() {
        checkAnswer(false)
    }

    private func setupUI() {
        view.backgroundColor = .ypBlack

        let buttonsStackView = UIStackView(arrangedSubviews: [noButton, yesButton])
        buttonsStackView.axis = .horizontal
        buttonsStackView.distribution = .fillEqually
        buttonsStackView.spacing = 8
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(imageView)
        view.addSubview(questionLabel)
        view.addSubview(counterLabel)
        view.addSubview(buttonsStackView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 75),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.32),

            questionLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 33),
            questionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            questionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),

            counterLabel.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 20),
            counterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            buttonsStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            buttonsStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            buttonsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -46),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 60),
            buttonsStackView.topAnchor.constraint(greaterThanOrEqualTo: counterLabel.bottomAnchor, constant: 24)
        ])

        yesButton.addTarget(self, action: #selector(yesButtonTapped), for: .touchUpInside)
        noButton.addTarget(self, action: #selector(noButtonTapped), for: .touchUpInside)
    }

    private func makeAnswerButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.setTitleColor(.ypBlack, for: .normal)
        button.backgroundColor = .ypWhite
        button.layer.cornerRadius = 15
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = UIColor.clear.cgColor
        questionLabel.text = step.question
        counterLabel.text = step.questionNumber
        setAnswerButtonsEnabled(true)
    }

    private func show(quiz result: QuizResultsViewModel) {
        let alertModel = AlertModel(
            title: result.title,
            message: result.text,
            buttonText: result.buttonText
        ) { [weak self] in
            self?.restartQuiz()
        }

        resultAlertPresenter.showAlert(model: alertModel)
    }

    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: model.image,
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }

    private func checkAnswer(_ answer: Bool) {
        guard let currentQuestion else { return }

        let isCorrect = answer == currentQuestion.correctAnswer
        if isCorrect {
            correctAnswers += 1
        }

        showAnswerResult(isCorrect: isCorrect)
    }

    private func showAnswerResult(isCorrect: Bool) {
        setAnswerButtonsEnabled(false)
        imageView.layer.borderWidth = imageBorderWidth
        imageView.layer.borderColor = (isCorrect ? UIColor.ypGreen : UIColor.ypRed).cgColor

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.showNextQuestionOrResults()
        }
    }

    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
            showResults()
        } else {
            currentQuestionIndex += 1
            questionFactory.requestNextQuestion()
        }
    }

    private func showResults() {
        statisticService.store(correct: correctAnswers, total: questionsAmount)

        let bestGame = statisticService.bestGame
        let bestGameDate = DateFormatter.movieQuiz.string(from: bestGame.date)
        let resultText = """
        Ваш результат: \(correctAnswers)/\(questionsAmount)
        Количество сыгранных квизов: \(statisticService.gamesCount)
        Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGameDate))
        Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
        """

        show(
            quiz: QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: resultText,
                buttonText: "Сыграть еще раз"
            )
        )
    }

    private func restartQuiz() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory.requestNextQuestion()
    }

    private func setAnswerButtonsEnabled(_ isEnabled: Bool) {
        yesButton.isEnabled = isEnabled
        noButton.isEnabled = isEnabled
        yesButton.alpha = isEnabled ? 1 : 0.5
        noButton.alpha = isEnabled ? 1 : 0.5
    }
}

extension MovieQuizViewController: QuestionFactoryDelegate {
    func didReceiveNextQuestion(_ question: QuizQuestion?) {
        guard let question else { return }

        currentQuestion = question
        let viewModel = convert(model: question)
        show(quiz: viewModel)
    }
}

private extension DateFormatter {
    static let movieQuiz: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy HH:mm"
        return formatter
    }()
}

private extension UIColor {
    static let ypBlack = UIColor(red: 26 / 255, green: 27 / 255, blue: 34 / 255, alpha: 1)
    static let ypWhite = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    static let ypGreen = UIColor(red: 43 / 255, green: 224 / 255, blue: 128 / 255, alpha: 1)
    static let ypRed = UIColor(red: 255 / 255, green: 59 / 255, blue: 48 / 255, alpha: 1)
}
