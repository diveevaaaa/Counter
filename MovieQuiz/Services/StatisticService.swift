import Foundation

protocol StatisticServiceProtocol {
    var gamesCount: Int { get }
    var bestGame: GameResult { get }
    var totalAccuracy: Double { get }

    func store(correct count: Int, total amount: Int)
}

final class StatisticService: StatisticServiceProtocol {
    private enum Keys {
        static let gamesCount = "gamesCount"
        static let bestGameCorrect = "bestGameCorrect"
        static let bestGameTotal = "bestGameTotal"
        static let bestGameDate = "bestGameDate"
        static let totalCorrectAnswers = "totalCorrectAnswers"
        static let totalQuestions = "totalQuestions"
    }

    private let storage: UserDefaults

    init(storage: UserDefaults = .standard) {
        self.storage = storage
    }

    var gamesCount: Int {
        storage.integer(forKey: Keys.gamesCount)
    }

    var bestGame: GameResult {
        GameResult(
            correct: storage.integer(forKey: Keys.bestGameCorrect),
            total: storage.integer(forKey: Keys.bestGameTotal),
            date: storage.object(forKey: Keys.bestGameDate) as? Date ?? Date()
        )
    }

    var totalAccuracy: Double {
        let totalQuestions = storage.integer(forKey: Keys.totalQuestions)
        guard totalQuestions > 0 else { return 0 }

        let totalCorrectAnswers = storage.integer(forKey: Keys.totalCorrectAnswers)
        return Double(totalCorrectAnswers) / Double(totalQuestions) * 100
    }

    func store(correct count: Int, total amount: Int) {
        let currentGame = GameResult(correct: count, total: amount, date: Date())
        let isFirstGame = gamesCount == 0
        let previousBestGame = bestGame

        storage.set(gamesCount + 1, forKey: Keys.gamesCount)
        storage.set(
            storage.integer(forKey: Keys.totalCorrectAnswers) + count,
            forKey: Keys.totalCorrectAnswers
        )
        storage.set(
            storage.integer(forKey: Keys.totalQuestions) + amount,
            forKey: Keys.totalQuestions
        )

        if isFirstGame || currentGame.isBetterThan(previousBestGame) {
            storage.set(currentGame.correct, forKey: Keys.bestGameCorrect)
            storage.set(currentGame.total, forKey: Keys.bestGameTotal)
            storage.set(currentGame.date, forKey: Keys.bestGameDate)
        }
    }
}
