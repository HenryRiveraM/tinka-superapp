import SwiftUI

enum TinkaTab: Hashable {
    case home, sales, voice, chat, wallet, profile
}

struct RootView: View {
    @StateObject private var appState = AppState.shared
    @State private var selectedTab: TinkaTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            TinkaTabBar(selected: $selectedTab)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
        .background(LinearGradient.tinkaSoftBackground.ignoresSafeArea())
        .environmentObject(appState)
        .ignoresSafeArea(.keyboard)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:    HomeDashboardView()
        case .sales:   SalesView()
        case .voice:   VoiceView()
        case .chat:    TinkaChatView()
        case .wallet:  WalletView()
        case .profile: ProfileView()
        }
    }
}

#Preview { RootView() }
