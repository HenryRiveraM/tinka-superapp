import SwiftUI

struct KPIRow: View {
    var body: some View {
        HStack(spacing: 12) {
            kpi(icon: "leaf.fill", title: "Salud", value: "Saludable", tint: TinkaColor.green)
            kpi(icon: "chart.bar.fill", title: "Crecimiento", value: "+18%", tint: TinkaColor.deepBlue)
            kpi(icon: "creditcard.fill", title: "Cashflow", value: "Estable", tint: TinkaColor.royalPurple)
        }
    }

    private func kpi(icon: String, title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle().fill(tint.opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(.tinka(10, weight: .semibold))
                .foregroundStyle(TinkaColor.subtleText)
            Text(value)
                .font(.tinka(14, weight: .bold))
                .foregroundStyle(TinkaColor.darkNavy)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard(cornerRadius: 20)
    }
}
