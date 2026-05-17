import SwiftUI

struct QuickActionsGrid: View {
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Acciones rápidas")
                .font(.tinka(15, weight: .bold))
                .foregroundStyle(TinkaColor.darkNavy)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(TinkaSampleData.quickActions) { action in
                    actionCard(action)
                }
            }
        }
    }

    private func actionCard(_ a: QuickAction) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: a.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                    .shadow(color: a.gradient.last!.opacity(0.4), radius: 8, y: 4)
                Image(systemName: a.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(a.title)
                .font(.tinka(12, weight: .bold))
                .foregroundStyle(TinkaColor.darkNavy)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 18)
    }
}
