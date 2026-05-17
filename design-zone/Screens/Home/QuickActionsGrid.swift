import SwiftUI

struct QuickActionsGrid: View {
    @Binding var selectedTab: TinkaTab
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private let actions: [(tab: TinkaTab, icon: String, title: String, gradient: [Color])] = [
        (.voice, "mic.fill", "Registrar\npor voz", [TinkaColor.magenta, TinkaColor.royalPurple]),
        (.sales, "plus.circle.fill", "Nueva\nventa", [TinkaColor.deepBlue, TinkaColor.royalPurple]),
        (.products, "tag.fill", "Editar\ncatálogo", [Color(hex: "0EA5E9"), TinkaColor.deepBlue]),
        (.reports, "chart.bar.doc.horizontal", "Ver\nreportes", [TinkaColor.royalPurple, TinkaColor.magenta])
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Acciones rápidas")
                .font(.tinka(15, weight: .bold))
                .foregroundStyle(TinkaColor.darkNavy)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(actions, id: \.tab) { action in
                    actionCard(action)
                }
            }
        }
    }

    private func actionCard(_ a: (tab: TinkaTab, icon: String, title: String, gradient: [Color])) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = a.tab
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: a.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                        .shadow(color: a.gradient.last?.opacity(0.4) ?? .clear, radius: 8, y: 4)
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
        .buttonStyle(.plain)
    }
}
