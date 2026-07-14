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
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private lazy var resultAlertPresenter = ResultAlertPresenter(viewController: self)
    private lazy var presenter: MovieQuizPresenter = {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        return MovieQuizPresenter(
            viewController: self,
            questionFactory: isUITesting ? MockQuestionFactory() : QuestionFactory(),
            answerDisplayDelay: isUITesting ? 0.05 : 1.0
        )
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInterface()
        presenter.viewDidLoad()
    }

    // MARK: - IBActions
    @IBAction private func yesButtonPressed(_ sender: UIButton) {
        presenter.yesButtonClicked()
    }

    @IBAction private func noButtonPressed(_ sender: UIButton) {
        presenter.noButtonClicked()
    }

    // MARK: - Private methods
    private func setupInterface() {
        view.backgroundColor = UIColor(named: "YPBlack")

        textLabel.text = "Вопрос:"
        textLabel.font = UIFont(name: "YSDisplay-Medium", size: 20)
        textLabel.textColor = UIColor(named: "YPWhite")

        counterLabel.accessibilityIdentifier = "questionCounter"
        counterLabel.font = UIFont(name: "YSDisplay-Medium", size: 20)
        counterLabel.textColor = UIColor(named: "YPWhite")

        imageView.accessibilityIdentifier = "moviePoster"
        questionLabel.font = UIFont(name: "YSDisplay-Bold", size: 23)
        questionLabel.textColor = UIColor(named: "YPWhite")

        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true

        configureButton(noButton, title: "Нет")
        configureButton(yesButton, title: "Да")
        configureLoadingIndicator()
    }

    private func configureButton(_ button: UIButton, title: String) {
        button.accessibilityIdentifier = title == "Да" ? "yesButton" : "noButton"
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont(name: "YSDisplay-Medium", size: 20)
        button.setTitleColor(UIColor(named: "YPBlack"), for: .normal)
        button.backgroundColor = UIColor(named: "YPWhite")
        button.layer.cornerRadius = 15
        button.layer.masksToBounds = true
    }

    private func configureLoadingIndicator() {
        loadingIndicator.color = UIColor(named: "YPWhite")
        loadingIndicator.accessibilityIdentifier = "loadingIndicator"
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setAnswerButtonsEnabled(_ isEnabled: Bool) {
        yesButton.isEnabled = isEnabled
        noButton.isEnabled = isEnabled
    }
}

// MARK: - MovieQuizViewControllerProtocol
extension MovieQuizViewController: MovieQuizViewControllerProtocol {
    func showLoadingIndicator() {
        setAnswerButtonsEnabled(false)
        loadingIndicator.startAnimating()
    }

    func hideLoadingIndicator() {
        loadingIndicator.stopAnimating()
        setAnswerButtonsEnabled(true)
    }

    func show(quiz step: QuizStepViewModel) {
        imageView.layer.borderWidth = 0
        imageView.image = UIImage(data: step.imageData) ?? UIImage()
        questionLabel.text = step.question
        counterLabel.text = step.questionNumber
    }

    func showQuizResult(isCorrect: Bool) {
        setAnswerButtonsEnabled(false)

        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect
            ? UIColor(named: "YPGreen")?.cgColor
            : UIColor(named: "YPRed")?.cgColor
    }

    func show(quiz result: QuizResultsViewModel) {
        imageView.layer.borderWidth = 0

        let alertModel = AlertModel(
            title: result.title,
            message: result.text,
            buttonText: result.buttonText
        ) { [weak self] in
            self?.presenter.restartGame()
        }
        resultAlertPresenter.showAlert(model: alertModel)
    }

    func showNetworkError(message: String) {
        hideLoadingIndicator()
        setAnswerButtonsEnabled(false)

        let alertModel = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать ещё раз"
        ) { [weak self] in
            self?.presenter.retryLoading()
        }
        resultAlertPresenter.showAlert(model: alertModel)
    }
}
