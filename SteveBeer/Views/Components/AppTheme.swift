import SwiftUI

enum AppTheme {
    static let background = Color(hex: "F6F0E6")
    static let cardBackground = Color(hex: "FFF9F0")
    static let tallAmber = Color(hex: "C77A1C")
    static let normalGolden = Color(hex: "E3B23C")
    static let ink = Color(hex: "4D3A23")
    static let outline = Color(hex: "BFA37A")
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue)
    }
}
