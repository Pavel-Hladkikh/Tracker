import UIKit

extension UIColor {
    static func dynamicHex(light: String, dark: String, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) -> UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor.hex(dark, alpha: darkAlpha)
            : UIColor.hex(light, alpha: lightAlpha)
        }
    }
}

enum Colors {
    static let base = UIColor.dynamicHex(light: "#FFFFFF", dark: "#1A1B22")
    static let baseInverse     = UIColor.dynamicHex(light: "#1A1B22", dark: "#FFFFFF")
    static let cardStroke       = UIColor.dynamicHex(light: "#E6E8EB", dark: "#414141", lightAlpha: 0.3, darkAlpha: 0.85)
    static let searchBackground = UIColor.dynamicHex(light: "#767680", dark: "#767680", lightAlpha: 0.12, darkAlpha: 0.24)
    static let contextMenuBackground = UIColor.dynamicHex(light: "#F2F2F2", dark: "#252525", lightAlpha: 0.8, darkAlpha: 0.5)
    static let searchText = UIColor.dynamicHex(light: "#AEAFB4", dark: "#EBEBF5")
}
