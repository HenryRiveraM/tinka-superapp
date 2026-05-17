import SwiftUI

struct WeeklyTrendCard: View {
    private let data = TinkaSampleData.trend
    private var maxValue: Double { data.map(\.value).max() ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            chart
            footer
        }
        .padding(18)
        .glassCard()
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tendencia semanal")
                    .font(.tinka(15, weight: .bold))
                    .foregroundStyle(TinkaColor.darkNavy)
                Text("Ingresos por día")
                    .font(.tinka(11, weight: .medium))
                    .foregroundStyle(TinkaColor.subtleText)
            }
            Spacer()
            Text("Bs. 3.120")
                .font(.tinka(14, weight: .bold))
                .foregroundStyle(TinkaColor.darkNavy)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(TinkaColor.lightGray))
        }
    }

    private var chart: some View {
        GeometryReader { geo in
            let chartHeight: CGFloat = geo.size.height
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(data) { point in
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(TinkaColor.lightGray)
                                .frame(maxWidth: .infinity)
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(LinearGradient.tinkaPrimary)
                                .frame(height: barHeight(point.value, available: chartHeight - 18))
                        }
                        Text(point.day)
                            .font(.tinka(10, weight: .semibold))
                            .foregroundStyle(TinkaColor.subtleText)
                    }
                }
            }
        }
        .frame(height: 130)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up.right.circle.fill")
                .foregroundStyle(TinkaColor.green)
            Text("Viernes fue tu mejor día — Bs. 690")
                .font(.tinka(12, weight: .semibold))
                .foregroundStyle(TinkaColor.darkNavy)
            Spacer()
        }
    }

    private func barHeight(_ value: Double, available: CGFloat) -> CGFloat {
        let ratio = value / maxValue
        return max(8, available * ratio)
    }
}
