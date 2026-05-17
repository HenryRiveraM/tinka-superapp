import SwiftUI

enum TinkaTab: Hashable {
    case home, sales, voice, chat, products, reports, profile
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
            LinearGradient(colors: [Color(hex: "0A0F1E"), Color(hex: "1A0F3E")],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(LinearGradient.tinkaPrimary).frame(width: 90, height: 90)
                        .shadow(color: TinkaColor.magenta.opacity(0.5), radius: 24)
                    Text("T").font(.tinka(48, weight: .black)).foregroundColor(.white)
                }
                Text("Tinka").font(.tinka(36, weight: .black)).foregroundColor(.white)
                ProgressView().tint(TinkaColor.magenta).scaleEffect(1.2).padding(.top, 8)
            }
        }
    }

    // MARK: - Main App
    private var mainApp: some View {
        ZStack(alignment: .bottom) {
            tabContent.frame(maxWidth: .infinity, maxHeight: .infinity)
            TinkaTabBar(selected: $selectedTab)
                .padding(.horizontal, 10).padding(.bottom, 8)
        }
        .background(LinearGradient.tinkaSoftBackground.ignoresSafeArea())
        .environmentObject(appState)
        .ignoresSafeArea(.keyboard)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:     HomeDashboardView()
        case .sales:    SalesView()
        case .voice:    VoiceView()
        case .chat:     TinkaChatView()
        case .products: ProductCatalogView()
        case .reports:  ReportsView()
        case .profile:  ProfileView()
        }
    }
}

#Preview { RootView() }
