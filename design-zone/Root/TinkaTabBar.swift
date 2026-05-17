import SwiftUI

struct TinkaTabBar: View {
    @Binding var selected: TinkaTab

    private let items: [(TinkaTab, String, String)] = [
        (.home,     "house.fill",              "Inicio"),
        (.sales,    "cart.fill",               "Ventas"),
        (.voice,    "mic.fill",                "Voz"),
        (.chat,     "sparkles",                "IA"),
        (.products, "tag.fill",                "Catálogo"),
        (.reports,  "chart.bar.doc.horizontal","Reportes"),
        (.profile,  "person.fill",             "Perfil")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.0) { item in
                tabButton(tab: item.0, icon: item.1, label: item.2)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white.opacity(0.55)))
        )
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Color.white.opacity(0.7), lineWidth: 1))
        .shadow(color: TinkaColor.royalPurple.opacity(0.18), radius: 20, x: 0, y: 8)
    }

    @ViewBuilder
    private func tabButton(tab: TinkaTab, icon: String, label: String) -> some View {
        let isVoice = (tab == .voice)
        let isSelected = (tab == selected)
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selected = tab }
        } label: {
            if isVoice {
                voiceButton(isSelected: isSelected)
            } else {
                standardButton(icon: icon, label: label, isSelected: isSelected)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func standardButton(icon: String, label: String, isSelected: Bool) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold))
            Text(label).font(.tinka(8, weight: .semibold))
        }
        .foregroundStyle(isSelected ? AnyShapeStyle(LinearGradient.tinkaPrimary) : AnyShapeStyle(TinkaColor.subtleText))
        .padding(.vertical, 7).padding(.horizontal, 2)
    }

    private func voiceButton(isSelected: Bool) -> some View {
        ZStack {
            Circle().fill(LinearGradient.tinkaPrimary).frame(width: 44, height: 44)
                .shadow(color: TinkaColor.magenta.opacity(0.5), radius: 12, x: 0, y: 5)
            Image(systemName: "mic.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
        }
        .offset(y: -6)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

#Preview { TinkaTabBar(selected: .constant(.home)) }
