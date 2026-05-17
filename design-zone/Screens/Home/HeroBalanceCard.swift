import SwiftUI

struct HeroBalanceCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient.tinkaPrimary)

            // decorative glow shapes
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 180, height: 180)
                .offset(x: 140, y: -70)
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 120, height: 120)
                .offset(x: -130, y: 60)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Ventas de hoy", systemImage: "sparkles")
                        .font(.tinka(12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.18)))
                    Spacer()
                    Text("BOB")
                        .font(.tinka(11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 1))
                }

                Text("Bs. \(Int(TinkaSampleData.todaySales)),00")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                    Text("+24% vs ayer")
                        .font(.tinka(12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(TinkaColor.green.opacity(0.85)))

                Divider().background(Color.white.opacity(0.25)).padding(.vertical, 2)

                HStack {
                    miniStat(title: "Semana", value: "Bs. 3.120")
                    Spacer()
                    Rectangle().fill(Color.white.opacity(0.25)).frame(width: 1, height: 30)
                    Spacer()
                    miniStat(title: "Utilidad", value: "Bs. 1.240")
                    Spacer()
                    Rectangle().fill(Color.white.opacity(0.25)).frame(width: 1, height: 30)
                    Spacer()
                    miniStat(title: "Ticket", value: "Bs. 24")
                }
            }
            .padding(22)
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: TinkaColor.royalPurple.opacity(0.35), radius: 24, x: 0, y: 14)
    }

    private func miniStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.tinka(10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.tinka(13, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}
