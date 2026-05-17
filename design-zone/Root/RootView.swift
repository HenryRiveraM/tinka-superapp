import SwiftUI

enum TinkaTab: Hashable {
    case home, sales, voice, products, reports, profile
}

struct RootView: View {
    @StateObject private var appState = AppState.shared
    @StateObject private var auth = AuthService.shared
    @State private var selectedTab: TinkaTab = .home

    var body: some View {
        Group {
            if auth.isLoading {
                splashScreen
            } else if auth.isLoggedIn {
                mainApp
            } else {
                LoginView()
            }
        }
        .task { await auth.initialize() }
    }

    // MARK: - Splash
    private var splashScreen: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 34) {
                Spacer()
                TinkaSplashLogo()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.05)
                    .opacity(0.85)
                Spacer()
            }
            .offset(y: 34)
        }
    }

    // MARK: - Main App
    private var mainApp: some View {
        ZStack(alignment: .bottom) {
            tabContent.frame(maxWidth: .infinity, maxHeight: .infinity)
            TinkaTabBar(selected: $selectedTab)
                .padding(.horizontal, 10).padding(.bottom, 8)
        }
        .background(TinkaBackgroundView(style: .light))
        .environmentObject(appState)
        .ignoresSafeArea(.keyboard)
        .task(id: auth.isLoggedIn) {
            guard auth.isLoggedIn else { return }
            await appState.loadFromSupabase()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:     HomeDashboardView(selectedTab: $selectedTab)
        case .sales:    SalesView()
        case .voice:    VoiceView()
        case .products: ProductCatalogView()
        case .reports:  ReportsView()
        case .profile:  ProfileView()
        }
    }
}

#Preview { RootView() }
