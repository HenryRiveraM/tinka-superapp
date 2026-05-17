import SwiftUI
import UIKit

struct ReportsView: View {
    @EnvironmentObject var state: AppState
    @State private var selectedPeriod: AppPeriod = .week
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    private var filtered: [SaleItem] { state.salesForPeriod(selectedPeriod) }
    private var filteredTotal: Double { filtered.reduce(0) { $0 + $1.total } }
    private var filteredCount: Int { filtered.count }
    private var filteredTicket: Double { filteredCount > 0 ? filteredTotal / Double(filteredCount) : 0 }
    private var filteredUtility: Double { filteredTotal * 0.35 }
    private var productStats: [ProductStat] { computeProductStats(from: filtered) }

    var body: some View {
        ZStack {
            background
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    reportHeader
                    periodPicker
                    summaryCards
                    ReportChartCard()
                    topProductsCard
                    salesHistoryCard
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, 18).padding(.top, 8)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: shareItems)
        }
    }

    private var background: some View {
        TinkaBackgroundView(style: .light)
    }

    private var reportHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reportes").font(.tinka(28, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                Text("Resumen de tu negocio").font(.tinka(14)).foregroundColor(TinkaColor.subtleText)
            }
            Spacer()
            Button {
                exportPDF()
            } label: {
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
            ForEach(AppPeriod.allCases, id: \.self) { p in
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedPeriod = p }
                } label: {
                    Text(p.rawValue)
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

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                summaryTile(title: "Total vendido", value: "Bs. \(Int(filteredTotal))", icon: "cart.fill", color: TinkaColor.deepBlue)
                summaryTile(title: "# Ventas", value: "\(filteredCount)", icon: "list.bullet.rectangle.fill", color: TinkaColor.royalPurple)
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
                Image(systemName: icon).font(.system(size: 17)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.tinka(11, weight: .medium)).foregroundColor(TinkaColor.subtleText)
                Text(value).font(.tinka(16, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                    .animation(.spring(response: 0.4), value: value)
            }
            Spacer()
        }
        .padding(14).glassCard(cornerRadius: 16).frame(maxWidth: .infinity)
    }

    private var topProductsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Productos más vendidos").font(.tinka(15, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                Spacer()
                Text(selectedPeriod.rawValue).font(.tinka(12)).foregroundColor(TinkaColor.subtleText)
            }
            if productStats.isEmpty {
                emptyProductsState
            } else {
                let maxQty = productStats.first?.qty ?? 1
                ForEach(productStats.prefix(5), id: \.name) { item in
                    productBar(item: item, maxQty: maxQty)
                }
            }
        }
        .padding(18).glassCard()
    }

    private var emptyProductsState: some View {
        HStack {
            Image(systemName: "chart.bar").font(.system(size: 24)).foregroundColor(TinkaColor.subtleText.opacity(0.4))
            Text("No hay ventas en este período").font(.tinka(13)).foregroundColor(TinkaColor.subtleText)
        }
        .padding(.vertical, 8)
    }

    private func productBar(item: ProductStat, maxQty: Int) -> some View {
        let pct = maxQty > 0 ? Double(item.qty) / Double(maxQty) : 0
        return VStack(spacing: 5) {
            HStack {
                Text(item.name).font(.tinka(14, weight: .medium)).foregroundColor(TinkaColor.darkNavy)
                Spacer()
                Text("\(item.qty) uds · Bs. \(Int(item.revenue))").font(.tinka(12)).foregroundColor(TinkaColor.subtleText)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(TinkaColor.lightGray).frame(maxWidth: .infinity, maxHeight: 8)
                    RoundedRectangle(cornerRadius: 4).fill(LinearGradient.tinkaPrimary).frame(width: geo.size.width * pct, height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    private var salesHistoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Historial de ventas").font(.tinka(15, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                Spacer()
                Text("\(filtered.count) registros").font(.tinka(12)).foregroundColor(TinkaColor.subtleText)
            }
            if filtered.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock").font(.system(size: 28)).foregroundColor(TinkaColor.subtleText.opacity(0.4))
                    Text("No hay ventas en este período.").font(.tinka(13)).foregroundColor(TinkaColor.subtleText)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 16)
            } else {
                ForEach(filtered.prefix(15)) { sale in
                    historyRow(sale: sale)
                    if sale.id != filtered.prefix(15).last?.id { Divider() }
                }
                if filtered.count > 15 {
                    Text("+ \(filtered.count - 15) ventas más").font(.tinka(12)).foregroundColor(TinkaColor.subtleText).frame(maxWidth: .infinity).padding(.top, 4)
                }
            }
        }
        .padding(18).glassCard()
    }

    private func historyRow(sale: SaleItem) -> some View {
        let chIcon = channelIcon(sale.channel)
        let chColor = channelColor(sale.channel)
        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(chColor.opacity(0.14)).frame(width: 36, height: 36)
                Image(systemName: chIcon).font(.system(size: 14)).foregroundColor(chColor)
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

    private func computeProductStats(from sales: [SaleItem]) -> [ProductStat] {
        var map: [String: (qty: Int, revenue: Double)] = [:]
        for sale in sales {
            for p in sale.products {
                let ex = map[p.name] ?? (0, 0)
                map[p.name] = (ex.qty + p.qty, ex.revenue + p.subtotal)
            }
        }
        return map.map { ProductStat(name: $0.key, qty: $0.value.qty, revenue: $0.value.revenue) }
                  .sorted { $0.qty > $1.qty }
    }

    private func generateReportText() -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "es_BO")
        fmt.dateStyle = .medium
        let topProds = productStats.prefix(3).map { "\($0.name): \($0.qty) uds (Bs. \(Int($0.revenue)))" }.joined(separator: "\n  ")
        return """
        📊 REPORTE TINKA - \(selectedPeriod.rawValue.uppercased())
        Fecha: \(fmt.string(from: Date()))
        Negocio: \(state.businessDisplayName)
        ─────────────────────────
        💰 Total vendido: Bs. \(Int(filteredTotal))
        🛒 Número de ventas: \(filteredCount)
        🎯 Ticket promedio: Bs. \(Int(filteredTicket))
        💵 Utilidad estimada (35%): Bs. \(Int(filteredUtility))
        ─────────────────────────
        🏆 TOP PRODUCTOS:
          \(topProds.isEmpty ? "Sin datos" : topProds)
        ─────────────────────────
        📈 Tinka Score: \(state.tinkaScore)/100
        Estado: \(state.financialStatus)
        ─────────────────────────
        Generado por Tinka App
        """
    }

    private func exportPDF() {
        let url = ReportPDFExporter.makePDF(
            title: "Reporte Tinka - \(selectedPeriod.rawValue)",
            businessName: state.businessDisplayName,
            period: selectedPeriod.rawValue,
            total: filteredTotal,
            count: filteredCount,
            ticket: filteredTicket,
            utility: filteredUtility,
            score: state.tinkaScore,
            status: state.financialStatus,
            topProducts: Array(productStats.prefix(5)),
            fallbackReport: generateReportText()
        )
        shareItems = [url ?? generateReportText()]
        showShareSheet = true
    }
}

// MARK: - Product Stat
struct ProductStat { let name: String; let qty: Int; let revenue: Double }

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

enum ReportPDFExporter {
    static func makePDF(title: String,
                        businessName: String,
                        period: String,
                        total: Double,
                        count: Int,
                        ticket: Double,
                        utility: Double,
                        score: Int,
                        status: String,
                        topProducts: [ProductStat],
                        fallbackReport: String) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Tinka-\(UUID().uuidString)")
            .appendingPathExtension("pdf")

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                let margin: CGFloat = 48
                let navy = UIColor(red: 0.06, green: 0.08, blue: 0.16, alpha: 1)
                let purple = UIColor(red: 0.43, green: 0.14, blue: 0.78, alpha: 1)
                let magenta = UIColor(red: 0.82, green: 0.08, blue: 0.52, alpha: 1)
                let gray = UIColor(red: 0.43, green: 0.47, blue: 0.56, alpha: 1)

                func draw(_ text: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                          size: CGFloat, weight: UIFont.Weight, color: UIColor = navy) {
                    text.draw(in: CGRect(x: x, y: y, width: w, height: h), withAttributes: [
                        .font: UIFont.systemFont(ofSize: size, weight: weight),
                        .foregroundColor: color
                    ])
                }

                let headerRect = CGRect(x: margin, y: margin, width: pageRect.width - margin * 2, height: 96)
                let path = UIBezierPath(roundedRect: headerRect, cornerRadius: 20)
                purple.setFill()
                path.fill()
                magenta.withAlphaComponent(0.32).setFill()
                UIBezierPath(ovalIn: CGRect(x: headerRect.maxX - 130, y: headerRect.minY - 24, width: 170, height: 170)).fill()
                draw("TINKA", x: margin + 22, y: margin + 18, w: 150, h: 22, size: 13, weight: .bold, color: .white.withAlphaComponent(0.85))
                draw(title, x: margin + 22, y: margin + 42, w: 360, h: 34, size: 24, weight: .bold, color: .white)
                draw(businessName, x: margin + 22, y: margin + 72, w: 320, h: 18, size: 12, weight: .semibold, color: .white.withAlphaComponent(0.82))

                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "es_BO")
                dateFormatter.dateStyle = .medium
                draw(dateFormatter.string(from: Date()), x: headerRect.maxX - 150, y: margin + 24, w: 128, h: 20, size: 12, weight: .semibold, color: .white)
                draw(period.uppercased(), x: headerRect.maxX - 150, y: margin + 48, w: 128, h: 20, size: 12, weight: .bold, color: .white.withAlphaComponent(0.88))

                let metricsY = headerRect.maxY + 28
                let cardW = (pageRect.width - margin * 2 - 18) / 2
                metricCard(title: "Total vendido", value: "Bs. \(Int(total))", x: margin, y: metricsY, w: cardW)
                metricCard(title: "Ventas", value: "\(count)", x: margin + cardW + 18, y: metricsY, w: cardW)
                metricCard(title: "Utilidad estimada", value: "Bs. \(Int(utility))", x: margin, y: metricsY + 88, w: cardW)
                metricCard(title: "Ticket promedio", value: "Bs. \(Int(ticket))", x: margin + cardW + 18, y: metricsY + 88, w: cardW)

                draw("Top productos", x: margin, y: metricsY + 205, w: 220, h: 24, size: 18, weight: .bold)
                if topProducts.isEmpty {
                    draw("Sin ventas registradas en este período.", x: margin, y: metricsY + 238, w: 360, h: 20, size: 12, weight: .regular, color: gray)
                } else {
                    for (idx, item) in topProducts.enumerated() {
                        let y = metricsY + 238 + CGFloat(idx * 34)
                        draw("\(idx + 1). \(item.name)", x: margin, y: y, w: 250, h: 22, size: 13, weight: .semibold)
                        draw("\(item.qty) uds · Bs. \(Int(item.revenue))", x: pageRect.width - margin - 160, y: y, w: 160, h: 22, size: 12, weight: .medium, color: gray)
                    }
                }

                let scoreY = pageRect.height - margin - 82
                draw("Tinka Score", x: margin, y: scoreY, w: 150, h: 24, size: 16, weight: .bold)
                draw("\(score)/100 · \(status)", x: margin, y: scoreY + 28, w: 240, h: 24, size: 14, weight: .semibold, color: purple)
                draw("Generado por Tinka App", x: pageRect.width - margin - 160, y: scoreY + 34, w: 160, h: 18, size: 11, weight: .medium, color: gray)

                func metricCard(title: String, value: String, x: CGFloat, y: CGFloat, w: CGFloat) {
                    let rect = CGRect(x: x, y: y, width: w, height: 70)
                    UIColor.white.setFill()
                    UIBezierPath(roundedRect: rect, cornerRadius: 16).fill()
                    UIColor(red: 0.88, green: 0.89, blue: 0.94, alpha: 1).setStroke()
                    UIBezierPath(roundedRect: rect, cornerRadius: 16).stroke()
                    draw(title, x: x + 16, y: y + 14, w: w - 32, h: 18, size: 11, weight: .semibold, color: gray)
                    draw(value, x: x + 16, y: y + 34, w: w - 32, h: 26, size: 20, weight: .bold, color: navy)
                }
            }
            return url
        } catch {
            NSLog("[Reports] PDF export failed: \(fallbackReport)")
            return nil
        }
    }
}

// MARK: - Report Chart Card
struct ReportChartCard: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        let trend = state.dailyTrend
        let maxVal = trend.map(\.value).max() ?? 1
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tendencia semanal").font(.tinka(15, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                    Text("Últimos 7 días").font(.tinka(11)).foregroundColor(TinkaColor.subtleText)
                }
                Spacer()
                Text("Bs. \(Int(state.weekSales))")
                    .font(.tinka(14, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                    .padding(.horizontal, 10).padding(.vertical, 6).background(Capsule().fill(TinkaColor.lightGray))
            }
            GeometryReader { geo in
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(trend, id: \.day) { point in
                        VStack(spacing: 4) {
                            if point.value > 0 {
                                Text("Bs.\(Int(point.value))")
                                    .font(.tinka(8)).foregroundColor(TinkaColor.subtleText).lineLimit(1).minimumScaleFactor(0.5)
                            }
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 8).fill(TinkaColor.lightGray).frame(maxWidth: .infinity)
                                RoundedRectangle(cornerRadius: 8).fill(LinearGradient.tinkaPrimary)
                                    .frame(height: Swift.max(8, (geo.size.height - 36) * (maxVal > 0 ? point.value / maxVal : 0)))
                            }
                            Text(point.day).font(.tinka(10, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
                        }
                    }
                }
            }
            .frame(height: 140)
            if let best = trend.max(by: { $0.value < $1.value }), best.value > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right.circle.fill").foregroundStyle(TinkaColor.green)
                    Text("Mejor día: \(best.day) — Bs. \(Int(best.value))").font(.tinka(12, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
                }
            }
        }
        .padding(18).glassCard()
    }
}

#Preview { ReportsView().environmentObject(AppState.shared) }
