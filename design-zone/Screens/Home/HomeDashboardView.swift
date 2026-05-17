import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject var state: AppState
    @Binding var selectedTab: TinkaTab
    @State private var animateScore = false

    var body: some View {
        ZStack {
            backgroundLayer
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    HomeHeaderView(selectedTab: $selectedTab)
                    HeroBalanceCard()
                    KPIRow()
                    TinkaScoreCard(animate: animateScore)
                    OnboardingChecklistView(selectedTab: $selectedTab)
                    AIInsightsSection(selectedTab: $selectedTab)
                    QuickActionsGrid(selectedTab: $selectedTab)
                    WeeklyTrendCard()
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
                animateScore = true
            }
        }
    }

    private var backgroundLayer: some View {
        TinkaBackgroundView(style: .light)
    }
}

struct OnboardingChecklistView: View {
    @EnvironmentObject var state: AppState
    @Binding var selectedTab: TinkaTab

    private var needsOnboarding: Bool {
        state.catalogProducts.count < 4 || state.sales.isEmpty || state.businessProfile == nil
    }

    var body: some View {
        if needsOnboarding {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Preparar cuenta")
                            .font(.tinka(16, weight: .bold))
                            .foregroundColor(TinkaColor.darkNavy)
                        Text("Completa estos pasos para que voz, reportes e IA tengan datos.")
                            .font(.tinka(12))
                            .foregroundColor(TinkaColor.subtleText)
                    }
                    Spacer()
                    Image(systemName: "sparkles")
                        .foregroundStyle(LinearGradient.tinkaPrimary)
                }
                VStack(spacing: 8) {
                    checklistRow(done: state.catalogProducts.count >= 4,
                                 title: "Catálogo con productos",
                                 action: "Catálogo",
                                 tab: .products)
                    checklistRow(done: !state.sales.isEmpty,
                                 title: "Primera venta registrada",
                                 action: "Vender",
                                 tab: .voice)
                    checklistRow(done: state.businessProfile != nil,
                                 title: "Perfil del negocio",
                                 action: "Perfil",
                                 tab: .profile)
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 18)
        }
    }

    private func checklistRow(done: Bool, title: String, action: String, tab: TinkaTab) -> some View {
        HStack(spacing: 10) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(done ? TinkaColor.green : TinkaColor.subtleText.opacity(0.55))
            Text(title)
                .font(.tinka(13, weight: .semibold))
                .foregroundColor(TinkaColor.darkNavy)
            Spacer()
            if !done {
                Button {
                    selectedTab = tab
                } label: {
                    Text(action)
                        .font(.tinka(11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(LinearGradient.tinkaPrimary)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

#Preview { HomeDashboardView(selectedTab: .constant(.home)).environmentObject(AppState.shared) }
