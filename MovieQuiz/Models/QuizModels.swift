import Foundation

struct QuizQuestion {
    let imageData: Data
    let text: String
    let correctAnswer: Bool
}

struct QuizStepViewModel {
    let imageData: Data
    let question: String
    let questionNumber: String
}

struct QuizResultsViewModel {
    let title: String
    let text: String
    let buttonText: String
}

struct AlertModel {
    let title: String
    let message: String
    let buttonText: String
    let completion: () -> Void
}

struct GameResult {
    let correct: Int
    let total: Int
    let date: Date

    func isBetterThan(_ another: GameResult) -> Bool {
        correct > another.correct
    }
}
