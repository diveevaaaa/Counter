import UIKit

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    var trackerHex: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return "FD4C49" }
        return String(format: "%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
    }

    convenience init(trackerHex: String) {
        var value: UInt64 = 0
        Scanner(string: trackerHex).scanHexInt64(&value)
        self.init(hex: UInt32(value))
    }

    static let ypBlack = UIColor(named: "ypBlack") ?? UIColor(hex: 0x1A1B22)
    static let ypWhite = UIColor(named: "ypWhite") ?? UIColor(hex: 0xFFFFFF)
    static let ypBackground = UIColor(named: "ypBackground") ?? UIColor(hex: 0xE6E8EB)
    static let ypGray = UIColor(named: "ypGray") ?? UIColor(hex: 0xAEAFB4)
    static let ypRed = UIColor(named: "ypRed") ?? UIColor(hex: 0xF56B6C)
    static let ypBlue = UIColor(named: "ypBlue") ?? UIColor(hex: 0x3772E7)
}
