import SwiftUI

struct AddSaleSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    @State private var quantities: [String: Int] = [:]
    @State private var note = ""
    @State private var confirming = false

    private var products: [String] {
        state.catalogProducts.filter { $0.isActive }.map { $0.name }
    }

    var total: Double {
        let catalog = state.catalogProducts
        return quantities.reduce(0) { acc, kv in
            let price = catalog.first { $0.name == kv.key }?.price ?? 0
            return acc + Double(kv.value) * price
        }
    }

    private func priceFor(_ name: String) -> Double {
        state.catalogProducts.first { $0.name == name }?.price ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.tinkaSoftBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    handle
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            productRows
                            if total > 0 { totalRow }
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

    private var handle: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3).fill(Color.gray.opacity(0.3)).frame(width: 36, height: 4).padding(.top, 12)
            HStack {
                Text("Nueva Venta Manual").font(.tinka(18, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 24)).foregroundColor(TinkaColor.subtleText)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var productRows: some View {
        VStack(spacing: 0) {
            ForEach(products, id: \.self) { product in
                let price = priceFor(product)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(product).font(.tinka(15, weight: .medium)).foregroundColor(TinkaColor.darkNavy)
                        Text("Bs. \(price, specifier: "%.0f") c/u").font(.tinka(12)).foregroundColor(TinkaColor.subtleText)
                    }
                    Spacer()
                    HStack(spacing: 14) {
                        Button {
                            if (quantities[product] ?? 0) > 0 { quantities[product, default: 0] -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill").font(.system(size: 26))
                                .foregroundColor((quantities[product] ?? 0) > 0 ? TinkaColor.deepBlue : TinkaColor.subtleText.opacity(0.3))
                        }
                        Text("\(quantities[product] ?? 0)").font(.tinka(16, weight: .bold)).foregroundColor(TinkaColor.darkNavy).frame(width: 24)
                        Button { quantities[product, default: 0] += 1 } label: {
                            Image(systemName: "plus.circle.fill").font(.system(size: 26)).foregroundColor(TinkaColor.deepBlue)
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
            VStack(alignment: .leading, spacing: 2) {
                Text("Total de venta").font(.tinka(13)).foregroundColor(TinkaColor.subtleText)
                Text("Bs. \(total, specifier: "%.2f")").font(.tinka(28, weight: .bold)).foregroundColor(TinkaColor.deepBlue)
                    .animation(.spring(response: 0.4), value: total)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").font(.system(size: 32)).foregroundColor(TinkaColor.green)
        }
        .padding(16).glassCard()
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nota (opcional)").font(.tinka(13, weight: .medium)).foregroundColor(TinkaColor.subtleText)
            TextField("Ej. cliente especial, descuento...", text: $note)
                .font(.tinka(14)).padding(12)
                .background(Color.white.opacity(0.7)).clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(TinkaColor.cardStroke))
        }
    }

    private var confirmButton: some View {
        Button {
            guard total > 0, !confirming else { return }
            confirming = true
            let prods = quantities.compactMap { kv -> SaleProduct? in
                guard kv.value > 0 else { return nil }
                return SaleProduct(name: kv.key, qty: kv.value, price: priceFor(kv.key))
            }
            state.addSale(SaleItem(date: Date(), products: prods, total: total, channel: .manual))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { dismiss() }
        } label: {
            HStack {
                if confirming {
                    ProgressView().tint(.white)
                    Text("Guardando...").font(.tinka(16, weight: .bold))
                } else {
                    Text(total > 0 ? "Confirmar — Bs. \(total, specifier: "%.2f")" : "Selecciona productos")
                        .font(.tinka(16, weight: .bold))
                }
            }
            .foregroundColor(.white).frame(maxWidth: .infinity).padding(16)
            .background(total > 0 ? AnyShapeStyle(LinearGradient.tinkaPrimary) : AnyShapeStyle(Color.gray.opacity(0.35)))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: total > 0 ? TinkaColor.magenta.opacity(0.3) : .clear, radius: 10, y: 5)
        }
        .disabled(total == 0 || confirming)
    }
}

#Preview { AddSaleSheet().environmentObject(AppState.shared) }
