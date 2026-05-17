import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var state: AppState
    @State private var selectedPeriod: ReportPeriod = .week
    @State private var showExportAlert = false

    var body: some View {
        ZStack {
            background
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    reportHeader
                    periodPicker
                    summaryCards
                    DailyChartCard()
                    topProductCard
                    salesHistoryCard
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, 18).padding(.top, 8)
            }
        }
        .alert("Reporte generado", isPresented: $showExportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("El reporte de \(selectedPeriod.label) fue generado correctamente. Comparte con tu contador o guárdalo para tu seguimiento.")
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient.tinkaSoftBackground.ignoresSafeArea()
            Circle().fill(TinkaColor.deepBlue.opacity(0.14)).frame(width: 300).blur(radius: 90).offset(x: -120, y: -180)
        }
    }

    private var reportHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reportes").font(.tinka(28, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                Text("Resumen de tu negocio").font(.tinka(14)).foregroundColor(TinkaColor.subtleText)
            }
            Spacer()
            Button { showExportAlert = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 13, weight: .semibold))
                    Text("Exportar").font(.tinka(13, weight: .semibold))
                }
                .foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 9)
                .background(LinearGradient.tinkaPrimary).clipShape(Capsule())
                .shadow(color: TinkaColor.magenta.opacity(0.3), radius: 8, y: 4)
            }
        }
        .padding(.top, 8)
    }

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(ReportPeriod.allCases, id: \.self) { p in
                Button { withAnimation(.spring(response: 0.3)) { selectedPeriod = p } } label: {
                    Text(p.label)
                        .font(.tinka(13, weight: .semibold))
                        .foregroundColor(selectedPeriod == p ? .white : TinkaColor.subtleText)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(selectedPeriod == p ? AnyShapeStyle(LinearGradient.tinkaPrimary) : AnyShapeStyle(Color.clear))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.7)).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(TinkaColor.cardStroke))
    }

    private var filteredSales: [SaleItem] {
        let cal = Calendar.current
        return state.sales.filter { sale in
            switch selectedPeriod {
            case .today: return cal.isDateInToday(sale.date)
            case .week:
                let start = cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                return sale.date >= start
            case .month:
                let start = cal.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                return sale.date >= start
            }
        }
    }

    private var filteredTotal: Double { filteredSales.reduce(0) { $0 + $1.total } }
    private var filteredCount: Int { filteredSales.count }
    private var filteredTicket: Double { filteredCount > 0 ? filteredTotal / Double(filteredCount) : 0 }
    private var filteredUtility: Double { filteredTotal * 0.35 }

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                summaryTile(title: "Total vendido", value: "Bs. \(Int(filteredTotal))", icon: "bolivanosign.circle.fill", color: TinkaColor.deepBlue)
                summaryTile(title: "# Ventas", value: "\(filteredCount)", icon: "cart.fill", color: TinkaColor.royalPurple)
            }
            HStack(spacing: 12) {
                summaryTile(title: "Utilidad est.", value: "Bs. \(Int(filteredUtility))", icon: "arrow.up.circle.fill", color: TinkaColor.green)
                summaryTile(title: "Ticket prom.", value: "Bs. \(Int(filteredTicket))", icon: "tag.fill", color: TinkaColor.magenta)
            }
        }
    }

    private func summaryTile(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.tinka(11, weight: .medium)).foregroundColor(TinkaColor.subtleText)
                Text(value).font(.tinka(16, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
            }
            Spacer()
        }
        .padding(14).glassCard(cornerRadius: 16).frame(maxWidth: .infinity)
    }

    private var topProductCard: some View {
        let products = productBreakdown(from: filteredSales)
        return VStack(alignment: .leading, spacing: 14) {
            Text("Productos más vendidos").font(.tinka(15, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
            if products.isEmpty {
                Text("No hay datos para este período.").font(.tinka(13)).foregroundColor(TinkaColor.subtleText)
            } else {
                ForEach(products.prefix(5), id: \.name) { item in
                    productRow(item: item, total: products.first?.qty ?? 1)
                }
            }
        }
        .padding(18).glassCard()
    }

    private func productRow(item: ProductStat, total: Int) -> some View {
        let pct = total > 0 ? Double(item.qty) / Double(total) : 0
        return VStack(spacing: 6) {
            HStack {
                Text(item.name).font(.tinka(14, weight: .medium)).foregroundColor(TinkaColor.darkNavy)
                Spacer()
                Text("\(item.qty) uds · Bs. \(Int(item.revenue))").font(.tinka(12)).foregroundColor(TinkaColor.subtleText)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(TinkaColor.lightGray).frame(maxWidth: .infinity, maxHeight: 6)
                    RoundedRectangle(cornerRadius: 4).fill(LinearGradient.tinkaPrimary).frame(width: geo.size.width * pct, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private var salesHistoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Historial de ventas").font(.tinka(15, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
            if filteredSales.isEmpty {
                Text("No hay ventas en este período.").font(.tinka(13)).foregroundColor(TinkaColor.subtleText).padding(.top, 4)
            } else {
                ForEach(filteredSales.prefix(10)) { sale in
                    reportSaleRow(sale: sale)
                    if sale.id != filteredSales.prefix(10).last?.id { Divider() }
                }
            }
        }
        .padding(18).glassCard()
    }

    private func reportSaleRow(sale: SaleItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(channelColor(sale.channel).opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: channelIcon(sale.channel)).font(.system(size: 14)).foregroundColor(channelColor(sale.channel))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(sale.products.map { "\($0.qty)x \($0.name)" }.joined(separator: ", "))
                    .font(.tinka(13, weight: .medium)).foregroundColor(TinkaColor.darkNavy).lineLimit(1)
                Text(sale.date, style: .time).font(.tinka(11)).foregroundColor(TinkaColor.subtleText)
            }
            Spacer()
            Text("Bs. \(Int(sale.total))").font(.tinka(14, weight: .bold)).foregroundColor(TinkaColor.deepBlue)
        }
    }

    private func channelIcon(_ ch: SaleChannel) -> String {
        switch ch { case .voice: return "mic.fill"; case .quick: return "bolt.fill"; case .manual: return "pencil" }
    }
    private func channelColor(_ ch: SaleChannel) -> Color {
        switch ch { case .voice: return TinkaColor.magenta; case .quick: return TinkaColor.royalPurple; case .manual: return TinkaColor.deepBlue }
    }

    private func productBreakdown(from sales: [SaleItem]) -> [ProductStat] {
        var map: [String: (qty: Int, revenue: Double)] = [:]
        for sale in sales {
            for p in sale.products {
                let existing = map[p.name] ?? (0, 0)
                map[p.name] = (existing.qty + p.qty, existing.revenue + p.subtotal)
            }
        }
        return map.map { ProductStat(name: $0.key, qty: $0.value.qty, revenue: $0.value.revenue) }
                  .sorted { $0.qty > $1.qty }
    }
}

struct ProductStat { let name: String; let qty: Int; let revenue: Double }
enum ReportPeriod: CaseIterable { case today, week, month
    var label: String {
        switch self { case .today: return "Hoy"; case .week: return "Semana"; case .month: return "Mes" }
    }
}

// MARK: - Daily Chart Card
struct DailyChartCard: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        let trend = state.dailyTrend
        let maxVal = trend.map(\.value).max() ?? 1
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tendencia semanal").font(.tinka(15, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                    Text("Ventas por día · últimos 7 días").font(.tinka(11)).foregroundColor(TinkaColor.subtleText)
                }
                Spacer()
                Text("Bs. \(Int(state.weekSales))").font(.tinka(14, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(TinkaColor.lightGray))
            }
            GeometryReader { geo in
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(trend, id: \.day) { point in
                        VStack(spacing: 4) {
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 8).fill(TinkaColor.lightGray).frame(maxWidth: .infinity)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient.tinkaPrimary)
                                    .frame(height: barH(point.value, max: maxVal, available: geo.size.height - 20))
                            }
                            Text(point.day).font(.tinka(10, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
                        }
                    }
                }
            }
            .frame(height: 130)

            if let best = trend.max(by: { $0.value < $1.value }), best.value > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right.circle.fill").foregroundStyle(TinkaColor.green)
                    Text("Mejor día: \(best.day) — Bs. \(Int(best.value))").font(.tinka(12, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
                }
            }
        }
        .padding(18).glassCard()
    }

    private func barH(_ val: Double, max maxVal: Double, available: CGFloat) -> CGFloat {
        guard maxVal > 0 else { return 4 }
        return Swift.max(8, available * (val / maxVal))
    }
}

#Preview { ReportsView().environmentObject(AppState.shared) }
