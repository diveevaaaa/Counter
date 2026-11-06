import Foundation

enum RussianPlural {
    static func days(_ count: Int) -> String {
        let mod100 = count % 100
        let mod10 = count % 10
        let word: String
        if (11...14).contains(mod100) {
            word = "дней"
        } else if mod10 == 1 {
            word = "день"
        } else if (2...4).contains(mod10) {
            word = "дня"
        } else {
            word = "дней"
        }
        return "\(count) \(word)"
    }
}
