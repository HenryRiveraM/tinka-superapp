import SwiftUI

struct TinkaTabBar: View {
    @Binding var selected: TinkaTab

    private let items: [(TinkaTab, String, String)] = [
        (.home,     "house.fill",              "Inicio"),
        (.sales,    "cart.fill",               "Ventas"),
        (.voice,    "mic.fill",                "Voz"),
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
        .padding(.horizontal, 7)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(colors: [
                                Color.white.opacity(0.88),
                                Color.white.opacity(0.70),
                                TinkaColor.magenta.opacity(0.08)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                )
        )
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(Color.white.opacity(0.92), lineWidth: 1))
        .shadow(color: TinkaColor.royalPurple.opacity(0.16), radius: 24, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
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
        VStack(spacing: 4) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(LinearGradient.tinkaPrimary)
                        .frame(width: 34, height: 30)
                        .shadow(color: TinkaColor.magenta.opacity(0.35), radius: 8, y: 3)
                }
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
            }
            Text(label)
                .font(.tinka(8, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(isSelected ? .white : TinkaColor.subtleText)
        .frame(height: 50)
        .padding(.horizontal, 1)
    }

    private func voiceButton(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.96))
                .frame(width: 58, height: 58)
                .overlay(Circle().stroke(Color.white.opacity(0.95), lineWidth: 1))
                .shadow(color: TinkaColor.royalPurple.opacity(0.18), radius: 10, y: 5)
            Circle()
                .fill(LinearGradient.tinkaPrimary)
                .frame(width: 48, height: 48)
                .shadow(color: TinkaColor.magenta.opacity(0.5), radius: 14, x: 0, y: 6)
            Image(systemName: "mic.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
        }
        .offset(y: -8)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

#Preview { TinkaTabBar(selected: .constant(.home)) }
