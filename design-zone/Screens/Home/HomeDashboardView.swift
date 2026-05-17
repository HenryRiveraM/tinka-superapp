import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject var state: AppState
    @State private var animateScore = false

    var body: some View {
        ZStack {
            backgroundLayer
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    HomeHeaderView()
                    HeroBalanceCard()
                    KPIRow()
                    TinkaScoreCard(animate: animateScore)
                    AIInsightsSection()
                    QuickActionsGrid()
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
        ZStack {
            LinearGradient.tinkaSoftBackground.ignoresSafeArea()
            Circle()
                .fill(TinkaColor.magenta.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: 140, y: -260)
            Circle()
                .fill(TinkaColor.deepBlue.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: -160, y: -200)
        }
    }
}

#Preview { HomeDashboardView().environmentObject(AppState.shared) }
