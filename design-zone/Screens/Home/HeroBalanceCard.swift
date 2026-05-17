import SwiftUI

struct HeroBalanceCard: View {
    @EnvironmentObject var state: AppState

    private var growth: String {
        let yesterday = state.sales.filter {
            let d = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            return Calendar.current.isDate($0.date, inSameDayAs: d)
        }.reduce(0) { $0 + $1.total }
        guard yesterday > 0 else { return state.todaySales > 0 ? "↑ Nuevo día" : "—" }
        let pct = ((state.todaySales - yesterday) / yesterday) * 100
        return pct >= 0 ? "+\(Int(pct))% vs ayer" : "\(Int(pct))% vs ayer"
    }

    private var growthPositive: Bool {
        let yesterday = state.sales.filter {
            let d = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            return Calendar.current.isDate($0.date, inSameDayAs: d)
        }.reduce(0) { $0 + $1.total }
        return state.todaySales >= yesterday
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous).fill(LinearGradient.tinkaPrimary)
            LinearGradient(colors: [Color.white.opacity(0.18), .clear],
                           startPoint: .topTrailing,
                           endPoint: .bottomLeading)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 92)
                .rotationEffect(.degrees(-10))
                .offset(y: -82)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Ventas de hoy", systemImage: "sparkles")
                        .font(.tinka(12, weight: .semibold)).foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.18)))
                    Spacer()
                    Text("BOB").font(.tinka(11, weight: .bold)).foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 1))
                }
                Text("Bs. \(state.todaySales, specifier: "%.2f")")
                    .font(.system(size: 40, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                    .animation(.spring(response: 0.5), value: state.todaySales)
                HStack(spacing: 8) {
                    Image(systemName: growthPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 11, weight: .bold))
                    Text(growth).font(.tinka(12, weight: .semibold))
                }
                .foregroundStyle(.white).padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill((growthPositive ? TinkaColor.green : TinkaColor.red).opacity(0.8)))
                Divider().background(Color.white.opacity(0.25)).padding(.vertical, 2)
                HStack {
                    miniStat(title: "Semana", value: "Bs. \(Int(state.weekSales))")
                    Spacer()
                    Rectangle().fill(Color.white.opacity(0.25)).frame(width: 1, height: 30)
                    Spacer()
                    miniStat(title: "Utilidad", value: "Bs. \(Int(state.utilityEstimate))")
                    Spacer()
                    Rectangle().fill(Color.white.opacity(0.25)).frame(width: 1, height: 30)
                    Spacer()
                    miniStat(title: "Ticket", value: "Bs. \(Int(state.averageTicket))")
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
            Text(title).font(.tinka(10, weight: .semibold)).foregroundStyle(.white.opacity(0.7))
            Text(value).font(.tinka(13, weight: .bold)).foregroundStyle(.white)
        }
    }
}
