import SwiftUI

// MARK: - Colors

enum AppTheme {
    // Backgrounds
    static let background   = Color(hex: "0f0f0f")
    static let surface      = Color(hex: "1a1a1a")
    static let surface2     = Color(hex: "242424")
    static let surface3     = Color(hex: "2e2e2e")
    static let border       = Color(hex: "333333")

    // Brand
    static let accent       = Color(hex: "e8ff47")  // Yellow-green primary CTA
    static let deload       = Color(hex: "f5c842")  // Amber for deload

    // Text
    static let textPrimary  = Color(hex: "f0f0f0")
    static let textSecondary = Color(hex: "999999")
    static let textTertiary  = Color(hex: "666666")

    // Status
    static let green        = Color(hex: "4ade80")
    static let red          = Color(hex: "f87171")
    static let orange       = Color(hex: "fb923c")
    static let blue         = Color(hex: "60a5fa")
}

// MARK: - Typography

extension Font {
    /// Giant number / lift name headline (e.g. weight display, exercise name)
    static var ironLogDisplay: Font { .system(size: 34, weight: .bold, design: .rounded) }
    /// Section headers and screen titles
    static var ironLogTitle: Font   { .system(size: 22, weight: .bold) }
    /// Subsection labels
    static var ironLogHeadline: Font { .system(size: 17, weight: .semibold) }
    /// Primary body text
    static var ironLogBody: Font    { .system(size: 15, weight: .regular) }
    /// Secondary labels, captions
    static var ironLogCaption: Font { .system(size: 13, weight: .regular) }
    /// Tiny metadata
    static var ironLogMicro: Font   { .system(size: 11, weight: .regular) }
}

// MARK: - Spacing

enum Spacing {
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 16
    static let lg: CGFloat  = 24
    static let xl: CGFloat  = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum Radius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}

// MARK: - Color+Hex Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - View Modifiers

extension View {
    /// Standard dark card surface
    func ironLogCard() -> some View {
        self
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    /// Accent-colored primary action button style
    func ironLogPrimaryButton() -> some View {
        self
            .font(.ironLogHeadline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    /// Secondary ghost-style button
    func ironLogSecondaryButton() -> some View {
        self
            .font(.ironLogHeadline)
            .foregroundColor(AppTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppTheme.surface2)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}
