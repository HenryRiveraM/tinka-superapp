import SwiftUI

enum TinkaTab: Hashable {
    case home, sales, voice, chat, wallet
}

struct RootView: View {
    @State private var selectedTab: TinkaTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:   HomeDashboardView()
                case .sales:  PlaceholderScreen(icon: "cart.fill", title: "Ventas", subtitle: "Tu historial de ventas y POS rápido vivirán aquí.")
                case .voice:  PlaceholderScreen(icon: "mic.fill", title: "Registro por voz", subtitle: "“Vendí tres salteñas y dos refrescos” — la magia llega pronto.")
                case .chat:   PlaceholderScreen(icon: "sparkles", title: "Tinka IA", subtitle: "Tu copiloto financiero conversacional.")
                case .wallet: PlaceholderScreen(icon: "creditcard.fill", title: "Billetera", subtitle: "Saldo, pagos QR y transferencias.")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            TinkaTabBar(selected: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
        .background(LinearGradient.tinkaSoftBackground.ignoresSafeArea())
    }
}

#Preview { RootView() }
