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
            date: storage.object(forKey: Keys.bestGameDate) as? Date ?? Date(timeIntervalSince1970: 0)
        )
    }

    var totalAccuracy: Double {
        let totalQuestions = storage.integer(forKey: Keys.totalQuestions)
        guard totalQuestions > 0 else { return 0 }

        let totalCorrectAnswers = storage.integer(forKey: Keys.totalCorrectAnswers)
        return Double(totalCorrectAnswers) / Double(totalQuestions) * 100
    }

    func store(correct count: Int, total amount: Int) {
        let previousGamesCount = gamesCount

        storage.set(previousGamesCount + 1, forKey: Keys.gamesCount)
        storage.set(storage.integer(forKey: Keys.totalCorrectAnswers) + count, forKey: Keys.totalCorrectAnswers)
        storage.set(storage.integer(forKey: Keys.totalQuestions) + amount, forKey: Keys.totalQuestions)

        let newResult = GameResult(correct: count, total: amount, date: Date())
        if previousGamesCount == 0 || newResult.isBetterThan(bestGame) {
            storage.set(newResult.correct, forKey: Keys.bestGameCorrect)
            storage.set(newResult.total, forKey: Keys.bestGameTotal)
            storage.set(newResult.date, forKey: Keys.bestGameDate)
        }
    }
}
