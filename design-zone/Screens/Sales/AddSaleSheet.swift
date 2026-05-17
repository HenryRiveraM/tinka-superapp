import SwiftUI

struct AddSaleSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    @State private var quantities: [String: Int] = ["Salteña": 0, "Refresco": 0, "Almuerzo": 0, "Pique Macho": 0]
    @State private var note = ""

    let products = ["Salteña", "Refresco", "Almuerzo", "Pique Macho"]

    var total: Double {
        quantities.reduce(0) { $0 + Double($1.value) * (ProductCatalog.prices[$1.key] ?? 0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.tinkaSoftBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    sheetHandle
                    ScrollView {
                        VStack(spacing: 20) {
                            productRows
                            totalRow
                            noteField
                            confirmButton
                        }
                        .padding(20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var sheetHandle: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3).fill(Color.gray.opacity(0.3)).frame(width: 36, height: 4).padding(.top, 12)
            Text("Nueva Venta Manual").font(.tinka(18, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
        }
    }

    private var productRows: some View {
        VStack(spacing: 0) {
            ForEach(products, id: \.self) { product in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(product).font(.tinka(15, weight: .medium)).foregroundColor(TinkaColor.darkNavy)
                        Text("Bs. \(ProductCatalog.prices[product] ?? 0, specifier: "%.0f") c/u").font(.tinka(12)).foregroundColor(TinkaColor.subtleText)
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        Button { if (quantities[product] ?? 0) > 0 { quantities[product, default: 0] -= 1 } } label: {
                            Image(systemName: "minus.circle.fill").font(.system(size: 24)).foregroundColor(TinkaColor.subtleText)
                        }
                        Text("\(quantities[product] ?? 0)").font(.tinka(16, weight: .bold)).foregroundColor(TinkaColor.darkNavy).frame(width: 24)
                        Button { quantities[product, default: 0] += 1 } label: {
                            Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundColor(TinkaColor.deepBlue)
                        }
                    }
                }
                .padding(.vertical, 14).padding(.horizontal, 16)
                if product != products.last { Divider().padding(.horizontal, 16) }
            }
        }
        .glassCard()
    }

    private var totalRow: some View {
        HStack {
            Text("Total").font(.tinka(16, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
            Spacer()
            Text("Bs. \(total, specifier: "%.2f")").font(.tinka(22, weight: .bold)).foregroundColor(TinkaColor.deepBlue)
        }
        .padding(16).glassCard()
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nota (opcional)").font(.tinka(13, weight: .medium)).foregroundColor(TinkaColor.subtleText)
            TextField("Ej. cliente especial, descuento...", text: $note)
                .font(.tinka(14)).padding(12)
                .background(Color.white.opacity(0.7)).clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var confirmButton: some View {
        Button {
            guard total > 0 else { return }
            let prods = quantities.compactMap { kv -> SaleProduct? in
                guard kv.value > 0 else { return nil }
                return SaleProduct(name: kv.key, qty: kv.value, price: ProductCatalog.prices[kv.key] ?? 0)
            }
            state.addSale(SaleItem(date: Date(), products: prods, total: total, channel: .manual))
            dismiss()
        } label: {
            Text(total > 0 ? "Confirmar — Bs. \(total, specifier: "%.2f")" : "Selecciona productos")
                .font(.tinka(16, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).padding(16)
                .background(total > 0 ? LinearGradient.tinkaPrimary : LinearGradient(colors: [Color.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: total > 0 ? TinkaColor.magenta.opacity(0.3) : .clear, radius: 10, y: 5)
        }
        .disabled(total == 0)
    }
}

#Preview { AddSaleSheet().environmentObject(AppState.shared) }
