import SwiftUI

enum TinkaColor {
    static let deepBlue = Color(hex: "0057B8")
    static let royalPurple = Color(hex: "6A1B9A")
    static let magenta = Color(hex: "E5007E")

    static let white = Color(hex: "FFFFFF")
    static let lightGray = Color(hex: "F8FAFC")
    static let darkNavy = Color(hex: "0F172A")

    static let green = Color(hex: "22C55E")
    static let yellow = Color(hex: "FACC15")
    static let red = Color(hex: "EF4444")

    static let cardStroke = Color.white.opacity(0.6)
    static let subtleText = Color(hex: "64748B")
}

extension LinearGradient {
    static let tinkaPrimary = LinearGradient(
        colors: [TinkaColor.deepBlue, TinkaColor.royalPurple, TinkaColor.magenta],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let tinkaSoftBackground = LinearGradient(
        colors: [
            TinkaColor.lightGray,
            Color(hex: "EEF2FF"),
            Color(hex: "FDF2F8")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let tinkaGlow = LinearGradient(
        colors: [TinkaColor.magenta.opacity(0.7), TinkaColor.royalPurple.opacity(0.7)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// Typography helpers (system rounded mimics Inter/Manrope feel)
extension Font {
    static func tinka(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// Reusable glass card style
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 24
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(0.45))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(TinkaColor.cardStroke, lineWidth: 1)
            )
            .shadow(color: TinkaColor.royalPurple.opacity(0.08), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 24) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}
