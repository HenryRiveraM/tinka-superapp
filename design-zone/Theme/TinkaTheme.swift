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
    static let surface = Color(hex: "FFFFFF")
    static let surfaceTint = Color(hex: "F4F7FB")
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
                    .fill(Color.white.opacity(0.82))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.9), lineWidth: 1)
            )
            .shadow(color: TinkaColor.royalPurple.opacity(0.10), radius: 18, x: 0, y: 8)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 24) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

enum TinkaBackgroundStyle {
    case light, dark, voice
}

struct TinkaBackgroundView: View {
    var style: TinkaBackgroundStyle = .light

    var body: some View {
        ZStack {
            baseGradient
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                LinearGradient(
                    colors: accentColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: w * 1.25, height: h * 0.48)
                .rotationEffect(.degrees(-12))
                .offset(x: -w * 0.12, y: -h * 0.14)
                .opacity(style == .dark ? 0.28 : 0.34)

                LinearGradient(
                    colors: secondaryColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: w * 1.3, height: h * 0.32)
                .rotationEffect(.degrees(14))
                .offset(x: w * 0.02, y: h * 0.74)
                .opacity(style == .dark ? 0.22 : 0.28)
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }

    private var baseGradient: LinearGradient {
        switch style {
        case .light:
            return LinearGradient(
                colors: [Color(hex: "F8FAFC"), Color(hex: "EEF4FF"), Color(hex: "FFF7FB")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dark, .voice:
            return LinearGradient(
                colors: [Color(hex: "070B18"), Color(hex: "10162B"), Color(hex: "170B2A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var accentColors: [Color] {
        switch style {
        case .light:
            return [TinkaColor.deepBlue.opacity(0.16), TinkaColor.royalPurple.opacity(0.10), .clear]
        case .dark:
            return [TinkaColor.deepBlue.opacity(0.40), TinkaColor.magenta.opacity(0.22), .clear]
        case .voice:
            return [TinkaColor.royalPurple.opacity(0.44), TinkaColor.magenta.opacity(0.26), .clear]
        }
    }

    private var secondaryColors: [Color] {
        switch style {
        case .light:
            return [.clear, TinkaColor.magenta.opacity(0.10), TinkaColor.deepBlue.opacity(0.08)]
        case .dark:
            return [.clear, TinkaColor.royalPurple.opacity(0.30), TinkaColor.deepBlue.opacity(0.18)]
        case .voice:
            return [.clear, TinkaColor.deepBlue.opacity(0.34), TinkaColor.magenta.opacity(0.20)]
        }
    }
}

struct TinkaBrandLogo: View {
    var size: CGFloat = 72
    var showFallbackLetter = true

    var body: some View {
        Image("BancoFieGlowLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size * 2.2, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.18, style: .continuous))
            .overlay {
                if showFallbackLetter {
                    RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                }
            }
            .shadow(color: TinkaColor.magenta.opacity(0.22), radius: size * 0.18, x: 0, y: size * 0.06)
            .accessibilityLabel("Banco Fie")
    }
}

struct TinkaSplashLogo: View {
    var body: some View {
        VStack(spacing: 18) {
            Image("TinkaAppIconLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 190, height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                .shadow(color: TinkaColor.magenta.opacity(0.34), radius: 28, x: 0, y: 16)
            Text("Tu copiloto financiero inteligente")
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.86))
        }
        .accessibilityLabel("Tinka, tu copiloto financiero inteligente")
    }
}

struct BancoFieLogoView: View {
    var height: CGFloat = 22

    var body: some View {
        Image("BancoFieLogo")
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .accessibilityLabel("Banco Fie")
    }
}

struct BancoFieGlowLogoView: View {
    var height: CGFloat = 46

    var body: some View {
        Image("BancoFieGlowLogo")
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .accessibilityLabel("Banco Fie")
    }
}
