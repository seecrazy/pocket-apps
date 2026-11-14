import SwiftUI

enum AtEaseDesignTokens {
    static let canvas = Color(red: 0.961, green: 0.949, blue: 0.929)
    static let breathBackground = Color(red: 0.055, green: 0.055, blue: 0.059)
    static let textPrimary = Color(red: 0.173, green: 0.173, blue: 0.180)
    static let textSecondary = Color(red: 0.557, green: 0.557, blue: 0.576)
    static let accentBreath = Color(red: 0.659, green: 0.773, blue: 0.820)

    static let moodColors: [Color] = [
        Color(red: 0.773, green: 0.835, blue: 0.796),
        Color(red: 0.839, green: 0.816, blue: 0.769),
        Color(red: 0.851, green: 0.784, blue: 0.706),
        Color(red: 0.831, green: 0.722, blue: 0.659),
        Color(red: 0.788, green: 0.663, blue: 0.604),
    ]

    static let moodTitles = ["平静", "还行", "一般", "低落", "焦躁"]
    static let pagePadding: CGFloat = 24
    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 32
}
