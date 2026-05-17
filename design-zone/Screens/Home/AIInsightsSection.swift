import SwiftUI

struct AIInsightsSection: View {
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
                Text("Ver todo")
                    .font(.tinka(12, weight: .semibold))
                    .foregroundStyle(TinkaColor.magenta)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TinkaSampleData.insights) { item in
                        insightCard(item)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func insightCard(_ item: AIInsight) -> some View {
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
            }
            Spacer(minLength: 0)
        }
        .frame(width: 250, alignment: .topLeading)
        .padding(14)
        .glassCard(cornerRadius: 20)
    }
}
