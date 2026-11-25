import Foundation

enum L10n {
    static func text(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: Bundle(for: BundleToken.self), value: key, comment: "")
    }

    static func days(_ count: Int) -> String {
        let language = Locale.current.language.languageCode?.identifier
        if language == "ru" {
            return RussianPlural.days(count)
        }
        let word = count == 1 ? "day" : "days"
        return "\(count) \(word)"
    }
}

private final class BundleToken {}
