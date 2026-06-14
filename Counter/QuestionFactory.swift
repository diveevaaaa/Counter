import UIKit

protocol QuestionFactoryProtocol {
    func requestNextQuestion()
}

protocol QuestionFactoryDelegate: AnyObject {
    func didReceiveNextQuestion(_ question: QuizQuestion?)
}

final class QuestionFactory: QuestionFactoryProtocol {
    private struct Movie {
        let title: String
        let rating: Double
    }

    weak var delegate: QuestionFactoryDelegate?

    private var currentQuestionIndex = 0
    private let movies: [Movie] = [
        Movie(title: "Крестный отец", rating: 9.2),
        Movie(title: "Темный рыцарь", rating: 9.0),
        Movie(title: "Криминальное чтиво", rating: 8.9),
        Movie(title: "Форрест Гамп", rating: 8.8),
        Movie(title: "Начало", rating: 8.8),
        Movie(title: "Интерстеллар", rating: 8.7),
        Movie(title: "Зеленая миля", rating: 8.6),
        Movie(title: "Бойцовский клуб", rating: 8.8),
        Movie(title: "Побег из Шоушенка", rating: 9.3),
        Movie(title: "Один дома 4", rating: 2.6),
        Movie(title: "Кошки", rating: 2.8),
        Movie(title: "Супербратья Марио", rating: 4.1)
    ].shuffled()

    init(delegate: QuestionFactoryDelegate?) {
        self.delegate = delegate
    }

    func requestNextQuestion() {
        guard !movies.isEmpty else {
            delegate?.didReceiveNextQuestion(nil)
            return
        }

        let movie = movies[currentQuestionIndex % movies.count]
        currentQuestionIndex += 1

        delegate?.didReceiveNextQuestion(
            QuizQuestion(
                image: makePosterImage(title: movie.title),
                text: "Рейтинг фильма «\(movie.title)» больше чем 6?",
                correctAnswer: movie.rating > 6
            )
        )
    }

    private func makePosterImage(title: String) -> UIImage {
        let size = CGSize(width: 640, height: 960)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            UIColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor(red: 0.22, green: 0.26, blue: 0.36, alpha: 1).setFill()
            context.fill(CGRect(x: 40, y: 40, width: 560, height: 880))

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.lineBreakMode = .byWordWrapping

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 52),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]

            let textRect = CGRect(x: 80, y: 360, width: 480, height: 240)
            title.draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
        }
    }
}
