import SwiftUI

struct AIInsightsSection: View {
    @EnvironmentObject var state: AppState
    @Binding var selectedTab: TinkaTab
    @State private var insights: [AIInsight] = []
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(LinearGradient.tinkaPrimary)
                    Text("Tinka IA sugiere")
                        .font(.tinka(15, weight: .bold))
                        .foregroundStyle(TinkaColor.darkNavy)
                }
                Spacer()
                if isLoading {
                    ProgressView()
                        .tint(TinkaColor.magenta)
                        .scaleEffect(0.75)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(currentInsights) { item in
                        insightCard(item)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .task(id: insightSignature) {
            await refreshInsights()
        }
    }

    private var currentInsights: [AIInsight] {
        insights.isEmpty ? localInsights : insights
    }

    private var localInsights: [AIInsight] {
        makeCards(from: TinkaLocalAI.insights(for: state))
    }

    private var insightSignature: String {
        "\(Int(state.todaySales))-\(Int(state.weekSales))-\(state.sales.count)-\(state.catalogProducts.count)-\(state.combos.count)-\(state.tinkaScore)"
    }

    private func insightCard(_ item: AIInsight) -> some View {
        Button {
            if let target = item.targetTab {
                selectedTab = target
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle().fill(item.tint.opacity(0.18)).frame(width: 36, height: 36)
                    Image(systemName: item.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(item.tint)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Insight")
                        .font(.tinka(9, weight: .bold))
                        .foregroundStyle(TinkaColor.subtleText)
                        .tracking(1.2)
                    Text(item.title)
                        .font(.tinka(13, weight: .semibold))
                        .foregroundStyle(TinkaColor.darkNavy)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    if let action = item.actionTitle {
                        Label(action, systemImage: "arrow.right.circle.fill")
                            .font(.tinka(11, weight: .bold))
                            .foregroundColor(item.tint)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(width: 250, alignment: .topLeading)
            .padding(14)
            .glassCard(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }

    private func refreshInsights() async {
        isLoading = true
        let text = await GeminiService.shared.insights(
            businessContext: state.businessContextForAI,
            state: state
        )
        await MainActor.run {
            insights = makeCards(from: text)
            isLoading = false
        }
    }

    private func makeCards(from text: [String]) -> [AIInsight] {
        let icons = ["chart.line.uptrend.xyaxis", "sparkles", "lightbulb.fill"]
        let tints = [TinkaColor.magenta, TinkaColor.green, TinkaColor.deepBlue]
        let actions: [(String, TinkaTab)] = [
            ("Ver reportes", .reports),
            ("Abrir catálogo", .products),
            ("Registrar venta", .voice)
        ]
        return Array(text.prefix(3)).enumerated().map { index, title in
            let action = actions[index % actions.count]
            return AIInsight(
                icon: icons[index % icons.count],
                title: title,
                tint: tints[index % tints.count],
                actionTitle: action.0,
                targetTab: action.1
            )
        }
    }
}
