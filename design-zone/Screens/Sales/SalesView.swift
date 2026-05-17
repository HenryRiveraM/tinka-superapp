import SwiftUI

struct SalesView: View {
    @EnvironmentObject var state: AppState
    @State private var filter: SalesFilter = .today
    @State private var showAddSale = false

    enum SalesFilter: String, CaseIterable {
        case today = "Hoy", week = "Semana", month = "Mes"
    }

    var filtered: [SaleItem] {
        let cal = Calendar.current
        return state.sales.filter { sale in
            switch filter {
            case .today: return cal.isDateInToday(sale.date)
            case .week:
                let start = cal.date(byAdding: .day, value: -7, to: Date())!
                return sale.date >= start
            case .month:
                let start = cal.date(byAdding: .month, value: -1, to: Date())!
                return sale.date >= start
            }
        }
    }

    var filteredTotal: Double { filtered.reduce(0) { $0 + $1.total } }

    var body: some View {
        ZStack(alignment: .bottom) {
            background
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    salesHeader
                    quickProductsSection
                    filterAndList
                    Color.clear.frame(height: 120)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            }
        }
        .sheet(isPresented: $showAddSale) { AddSaleSheet().environmentObject(state) }
    }

    private var background: some View {
        ZStack {
            LinearGradient.tinkaSoftBackground.ignoresSafeArea()
            Circle().fill(TinkaColor.deepBlue.opacity(0.15)).frame(width: 300).blur(radius: 80).offset(x: 150, y: -250)
        }
    }

    private var salesHeader: some View {
        VStack(spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ventas").font(.tinka(28, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                    Text(Date(), style: .date).font(.tinka(13)).foregroundColor(TinkaColor.subtleText)
                }
                Spacer()
                Button { showAddSale = true } label: {
                    Image(systemName: "plus").font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white).frame(width: 40, height: 40)
                        .background(LinearGradient.tinkaPrimary).clipShape(Circle())
                        .shadow(color: TinkaColor.magenta.opacity(0.35), radius: 8, y: 4)
                }
            }
            SalesTotalCard(total: filteredTotal, count: filtered.count, filter: filter.rawValue)
                .padding(.top, 8)
        }
    }

    private var quickProductsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Venta rápida").font(.tinka(16, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
            QuickSaleGrid().environmentObject(state)
        }
    }

    private var filterAndList: some View {
        VStack(alignment: .leading, spacing: 12) {
            filterPicker
            if filtered.isEmpty {
                emptySalesState
            } else {
                ForEach(filtered) { sale in SaleRowCard(sale: sale) }
            }
        }
    }

    private var filterPicker: some View {
        HStack(spacing: 8) {
            ForEach(SalesFilter.allCases, id: \.self) { f in
                filterChip(f)
            }
            Spacer()
        }
    }

    private func filterChip(_ f: SalesFilter) -> some View {
        let isSelected = filter == f
        return Button(f.rawValue) { withAnimation(.spring(response: 0.3)) { filter = f } }
            .font(.tinka(13, weight: isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? .white : TinkaColor.subtleText)
            .padding(.horizontal, 16).padding(.vertical, 7)
            .background(isSelected ? AnyShapeStyle(LinearGradient.tinkaPrimary) : AnyShapeStyle(Color.white.opacity(0.6)))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.clear : TinkaColor.cardStroke, lineWidth: 1))
    }

    private var emptySalesState: some View {
        VStack(spacing: 12) {
            Image(systemName: "cart").font(.system(size: 44)).foregroundColor(TinkaColor.subtleText.opacity(0.5))
            Text("Sin ventas aún").font(.tinka(16, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
            Text("Registra tu primera venta del día").font(.tinka(13)).foregroundColor(TinkaColor.subtleText.opacity(0.7))
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
                Text("\(count) venta\(count == 1 ? "" : "s") registrada\(count == 1 ? "" : "s")")
                    .font(.tinka(12)).foregroundColor(.white.opacity(0.75))
            }
            Spacer()
            Image(systemName: "cart.fill").font(.system(size: 40)).foregroundColor(.white.opacity(0.25))
        }
        .padding(20)
        .background(LinearGradient.tinkaPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: TinkaColor.royalPurple.opacity(0.3), radius: 16, y: 8)
    }
}

// MARK: - Quick Sale Grid
struct QuickSaleGrid: View {
    @EnvironmentObject var state: AppState
    @State private var quantities: [String: Int] = ["Salteña": 0, "Refresco": 0, "Almuerzo": 0, "Pique Macho": 0]
    @State private var showConfirm = false

    let products: [(name: String, icon: String, color: Color)] = [
        ("Salteña", "🫓", TinkaColor.magenta),
        ("Refresco", "🥤", TinkaColor.deepBlue),
        ("Almuerzo", "🍱", TinkaColor.royalPurple),
        ("Pique Macho", "🥩", Color(hex: "E97316"))
    ]

    var totalBs: Double {
        quantities.reduce(0) { $0 + Double($1.value) * (SeedData.products[$1.key] ?? 0) }
    }

    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(products, id: \.name) { p in QuickProductTile(name: p.name, emoji: p.icon, color: p.color, qty: quantities[p.name] ?? 0) {
                    quantities[p.name, default: 0] += 1
                } onRemove: {
                    if (quantities[p.name] ?? 0) > 0 { quantities[p.name, default: 0] -= 1 }
                }}
            }
            if totalBs > 0 {
                Button {
                    let products = quantities.compactMap { kv -> SaleProduct? in
                        guard kv.value > 0 else { return nil }
                        return SaleProduct(name: kv.key, qty: kv.value, price: SeedData.products[kv.key] ?? 0)
                    }
                    state.addSale(SaleItem(date: Date(), products: products, total: totalBs, channel: .quick))
                    quantities = quantities.mapValues { _ in 0 }
                } label: {
                    HStack {
                        Text("Confirmar venta").font(.tinka(16, weight: .semibold))
                        Spacer()
                        Text("Bs. \(totalBs, specifier: "%.0f")").font(.tinka(16, weight: .bold))
                    }
                    .foregroundColor(.white).padding(16)
                    .background(LinearGradient.tinkaPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: TinkaColor.magenta.opacity(0.3), radius: 10, y: 5)
                }
                .transition(.scale.combined(with: .opacity))
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
            Text(emoji).font(.system(size: 32))
            Text(name).font(.tinka(12, weight: .medium)).foregroundColor(TinkaColor.darkNavy).multilineTextAlignment(.center)
            Text("Bs. \(SeedData.products[name] ?? 0, specifier: "%.0f")").font(.tinka(11)).foregroundColor(TinkaColor.subtleText)
            HStack(spacing: 0) {
                Button(action: onRemove) { Image(systemName: "minus").font(.system(size: 12, weight: .bold)).foregroundColor(color).frame(width: 28, height: 28) }
                Text("\(qty)").font(.tinka(15, weight: .bold)).foregroundColor(TinkaColor.darkNavy).frame(width: 30)
                Button(action: onAdd) { Image(systemName: "plus").font(.system(size: 12, weight: .bold)).foregroundColor(.white).frame(width: 28, height: 28).background(color).clipShape(Circle()) }
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
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(TinkaColor.deepBlue.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: channelIcon).font(.system(size: 16)).foregroundColor(TinkaColor.deepBlue)
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
