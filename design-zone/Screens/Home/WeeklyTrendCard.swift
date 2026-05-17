import SwiftUI

struct WeeklyTrendCard: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        let trend = state.dailyTrend
        let maxVal = trend.map(\.value).max() ?? 1
        return VStack(alignment: .leading, spacing: 16) {
            header
            chart(trend: trend, maxVal: maxVal)
            footer(trend: trend)
        }
        .padding(18)
        .glassCard()
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tendencia semanal").font(.tinka(15, weight: .bold)).foregroundStyle(TinkaColor.darkNavy)
                Text("Ingresos por día").font(.tinka(11, weight: .medium)).foregroundStyle(TinkaColor.subtleText)
            }
            Spacer()
            Text("Bs. \(Int(state.weekSales))").font(.tinka(14, weight: .bold)).foregroundStyle(TinkaColor.darkNavy)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(TinkaColor.lightGray))
        }
    }

    private func chart(trend: [(day: String, value: Double)], maxVal: Double) -> some View {
        GeometryReader { geo in
            let chartHeight = geo.size.height
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(trend, id: \.day) { point in
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(TinkaColor.lightGray).frame(maxWidth: .infinity)
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(LinearGradient.tinkaPrimary)
                                .frame(height: barH(point.value, max: maxVal, avail: chartHeight - 18))
                        }
                        Text(point.day).font(.tinka(10, weight: .semibold)).foregroundStyle(TinkaColor.subtleText)
                    }
                }
            }
        }
        .frame(height: 130)
    }

    private func footer(trend: [(day: String, value: Double)]) -> some View {
        let best = trend.max(by: { $0.value < $1.value })
        return HStack(spacing: 8) {
            Image(systemName: "arrow.up.right.circle.fill").foregroundStyle(TinkaColor.green)
            if let best, best.value > 0 {
                Text("\(best.day) fue tu mejor día — Bs. \(Int(best.value))")
                    .font(.tinka(12, weight: .semibold)).foregroundStyle(TinkaColor.darkNavy)
            } else {
                Text("Registra ventas para ver tendencias").font(.tinka(12, weight: .semibold)).foregroundStyle(TinkaColor.darkNavy)
            }
            Spacer()
        }
    }

    private func barH(_ val: Double, max maxVal: Double, avail: CGFloat) -> CGFloat {
        guard maxVal > 0 else { return 4 }
        return Swift.max(8, avail * (val / maxVal))
    }
}
