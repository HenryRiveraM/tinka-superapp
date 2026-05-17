import SwiftUI

struct SalesView: View {
    @EnvironmentObject var state: AppState
    @State private var filter: AppPeriod = .today
    @State private var showAddSale = false

    var filtered: [SaleItem] { state.salesForPeriod(filter) }
    var filteredTotal: Double { filtered.reduce(0) { $0 + $1.total } }

    var body: some View {
        ZStack(alignment: .bottom) {
            background
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    salesHeader
                    SalesTotalCard(total: filteredTotal, count: filtered.count, filter: filter.rawValue)
                    quickSection
                    filterAndList
                    Color.clear.frame(height: 120)
                }
                .padding(.horizontal, 18).padding(.top, 8)
            }
        }
        .sheet(isPresented: $showAddSale) { AddSaleSheet().environmentObject(state) }
    }

    private var background: some View {
        TinkaBackgroundView(style: .light)
    }

    private var salesHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ventas").font(.tinka(28, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                Text(Date(), style: .date).font(.tinka(13)).foregroundColor(TinkaColor.subtleText)
            }
            Spacer()
            Button { showAddSale = true } label: {
                Image(systemName: "plus").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .frame(width: 42, height: 42).background(LinearGradient.tinkaPrimary).clipShape(Circle())
                    .shadow(color: TinkaColor.magenta.opacity(0.35), radius: 8, y: 4)
            }
        }
    }

    private var quickSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Venta rápida").font(.tinka(16, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
            QuickSaleGrid()
        }
    }

    private var filterAndList: some View {
        VStack(alignment: .leading, spacing: 12) {
            filterPicker
            if filtered.isEmpty { emptySalesState } else {
                ForEach(filtered) { sale in
                    SaleRowCard(sale: sale)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { state.deleteSale(sale.id) } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    private var filterPicker: some View {
        HStack(spacing: 8) {
            ForEach(AppPeriod.allCases, id: \.self) { p in
                filterChip(p)
            }
            Spacer()
        }
    }

    private func filterChip(_ p: AppPeriod) -> some View {
        let isSelected = filter == p
        return Button(p.rawValue) {
            withAnimation(.spring(response: 0.3)) { filter = p }
        }
        .font(.tinka(13, weight: isSelected ? .semibold : .regular))
        .foregroundColor(isSelected ? .white : TinkaColor.subtleText)
        .padding(.horizontal, 16).padding(.vertical, 7)
        .background(isSelected ? AnyShapeStyle(LinearGradient.tinkaPrimary) : AnyShapeStyle(Color.white.opacity(0.7)))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(isSelected ? Color.clear : TinkaColor.cardStroke, lineWidth: 1))
    }

    private var emptySalesState: some View {
        VStack(spacing: 14) {
            Image(systemName: "cart").font(.system(size: 40)).foregroundColor(TinkaColor.subtleText.opacity(0.4))
            Text("Sin ventas registradas").font(.tinka(16, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
            Text("Usa la venta rápida arriba\no el botón + para registrar").font(.tinka(13)).foregroundColor(TinkaColor.subtleText.opacity(0.7)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(40).glassCard()
    }
}

// MARK: - Sales Total Card
struct SalesTotalCard: View {
    let total: Double; let count: Int; let filter: String
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total \(filter)").font(.tinka(13)).foregroundColor(.white.opacity(0.8))
                Text("Bs. \(total, specifier: "%.2f")").font(.tinka(32, weight: .bold)).foregroundColor(.white)
                    .animation(.spring(response: 0.5), value: total)
                Text("\(count) venta\(count == 1 ? "" : "s") registrada\(count == 1 ? "" : "s")")
                    .font(.tinka(12)).foregroundColor(.white.opacity(0.75))
            }
            Spacer()
            Image(systemName: "cart.fill").font(.system(size: 40)).foregroundColor(.white.opacity(0.2))
        }
        .padding(20).background(LinearGradient.tinkaPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: TinkaColor.royalPurple.opacity(0.3), radius: 16, y: 8)
    }
}

// MARK: - Quick Sale Grid
struct QuickSaleGrid: View {
    @EnvironmentObject var state: AppState
    @State private var quantities: [String: Int] = [:]
    @State private var confirming = false

    var totalBs: Double {
        quantities.reduce(0) { $0 + Double($1.value) * (ProductCatalog.prices[$1.key] ?? 0) }
    }

    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(ProductCatalog.quickProducts, id: \.name) { p in
                    QuickProductTile(
                        name: p.name, emoji: p.emoji, color: p.color,
                        qty: quantities[p.name] ?? 0,
                        onAdd: { quantities[p.name, default: 0] += 1 },
                        onRemove: { if (quantities[p.name] ?? 0) > 0 { quantities[p.name, default: 0] -= 1 } }
                    )
                }
            }
            if totalBs > 0 {
                Button {
                    withAnimation { confirming = true }
                    let prods = quantities.compactMap { kv -> SaleProduct? in
                        guard kv.value > 0 else { return nil }
                        return SaleProduct(name: kv.key, qty: kv.value, price: ProductCatalog.prices[kv.key] ?? 0)
                    }
                    state.addSale(SaleItem(date: Date(), products: prods, total: totalBs, channel: .quick))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        quantities = [:]
                        confirming = false
                    }
                } label: {
                    HStack {
                        if confirming {
                            ProgressView().tint(.white).scaleEffect(0.85)
                            Text("Guardando...").font(.tinka(16, weight: .semibold))
                        } else {
                            Text("Confirmar venta").font(.tinka(16, weight: .semibold))
                            Spacer()
                            Text("Bs. \(totalBs, specifier: "%.0f")").font(.tinka(16, weight: .bold))
                        }
                    }
                    .foregroundColor(.white).padding(16)
                    .background(LinearGradient.tinkaPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: TinkaColor.magenta.opacity(0.3), radius: 10, y: 5)
                }
                .transition(.scale.combined(with: .opacity))
                .disabled(confirming)
            }
        }
        .padding(16).glassCard()
    }
}

struct QuickProductTile: View {
    let name: String; let emoji: String; let color: Color; let qty: Int
    let onAdd: () -> Void; let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji).font(.system(size: 30))
            Text(name).font(.tinka(12, weight: .medium)).foregroundColor(TinkaColor.darkNavy).multilineTextAlignment(.center).lineLimit(1).minimumScaleFactor(0.7)
            Text("Bs. \(ProductCatalog.prices[name] ?? 0, specifier: "%.0f")").font(.tinka(11)).foregroundColor(TinkaColor.subtleText)
            HStack(spacing: 0) {
                Button(action: onRemove) {
                    Image(systemName: "minus").font(.system(size: 11, weight: .bold)).foregroundColor(qty > 0 ? color : TinkaColor.subtleText)
                        .frame(width: 28, height: 28)
                }
                Text("\(qty)").font(.tinka(15, weight: .bold)).foregroundColor(TinkaColor.darkNavy).frame(width: 28)
                Button(action: onAdd) {
                    Image(systemName: "plus").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                        .frame(width: 28, height: 28).background(color).clipShape(Circle())
                }
            }
            .background(Color.white.opacity(0.8)).clipShape(Capsule())
        }
        .padding(12).frame(maxWidth: .infinity)
        .background(qty > 0 ? color.opacity(0.1) : Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(qty > 0 ? color.opacity(0.5) : TinkaColor.cardStroke, lineWidth: 1))
        .animation(.spring(response: 0.3), value: qty)
    }
}

// MARK: - Sale Row Card
struct SaleRowCard: View {
    let sale: SaleItem

    var channelIcon: String {
        switch sale.channel { case .voice: return "mic.fill"; case .manual: return "pencil"; case .quick: return "bolt.fill" }
    }
    var channelColor: Color {
        switch sale.channel { case .voice: return TinkaColor.magenta; case .manual: return TinkaColor.deepBlue; case .quick: return TinkaColor.royalPurple }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(channelColor.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: channelIcon).font(.system(size: 16)).foregroundColor(channelColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(sale.products.map { "\($0.qty)x \($0.name)" }.joined(separator: ", "))
                    .font(.tinka(13, weight: .medium)).foregroundColor(TinkaColor.darkNavy).lineLimit(2)
                Text(sale.date, style: .time).font(.tinka(11)).foregroundColor(TinkaColor.subtleText)
            }
            Spacer()
            Text("Bs. \(sale.total, specifier: "%.0f")").font(.tinka(15, weight: .bold)).foregroundColor(TinkaColor.deepBlue)
        }
        .padding(14).glassCard(cornerRadius: 16)
    }
}

#Preview { SalesView().environmentObject(AppState.shared) }
