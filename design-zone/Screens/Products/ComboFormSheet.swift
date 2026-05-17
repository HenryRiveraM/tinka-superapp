import SwiftUI

struct ComboFormSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    let combo: ProductCombo?

    @State private var name: String = ""
    @State private var finalPriceText: String = ""
    @State private var emoji: String = "🎁"
    @State private var selectedItems: [ComboItem] = []
    @State private var showEmojiPicker = false
    @State private var isSaving = false

    private let quickEmojis = ["🎁","🌅","💼","🍽️","🌮","🥗","🌯","🥞","🍱","☕","🥤","🫔","🎊","⭐","💫","🔥","🎯","✨","🏆","💎"]

    var isEditing: Bool { combo != nil }
    var regularTotal: Double { selectedItems.reduce(0) { $0 + $1.totalPrice } }
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && Double(finalPriceText) != nil
        && !selectedItems.isEmpty
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.tinkaSoftBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        emojiSection
                        nameSection
                        productsSection
                        priceSection
                    }
                    .padding(18)
                }
            }
            .navigationTitle(isEditing ? "Editar Combo" : "Nuevo Combo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }.foregroundColor(TinkaColor.subtleText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .font(.tinka(15, weight: .bold))
                        .foregroundStyle(isValid ? AnyShapeStyle(LinearGradient.tinkaPrimary) : AnyShapeStyle(Color.gray))
                        .disabled(!isValid || isSaving)
                }
            }
        }
        .onAppear {
            if let c = combo {
                name = c.name; finalPriceText = String(format: "%.0f", c.finalPrice)
                emoji = c.emoji; selectedItems = c.items
            }
        }
    }

    private var emojiSection: some View {
        VStack(spacing: 8) {
            Button { withAnimation { showEmojiPicker.toggle() } } label: {
                ZStack {
                    Circle().fill(LinearGradient.tinkaPrimary.opacity(0.12)).frame(width: 80, height: 80)
                    Text(emoji).font(.system(size: 40))
                }
            }
            if showEmojiPicker {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 8) {
                    ForEach(quickEmojis, id: \.self) { e in
                        Button { emoji = e; showEmojiPicker = false } label: {
                            Text(e).font(.system(size: 24))
                                .frame(width: 32, height: 32)
                                .background(emoji == e ? TinkaColor.magenta.opacity(0.15) : Color.clear)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(10)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    private var nameSection: some View {
        FormFieldView(label: "Nombre del combo", placeholder: "Ej: Combo Desayuno, Ejecutivo...", text: $name)
    }

    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Productos del combo").font(.tinka(13, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
            let active = state.catalogProducts.filter { $0.isActive }
            if active.isEmpty {
                Text("Agrega productos al catálogo primero")
                    .font(.tinka(13)).foregroundColor(TinkaColor.subtleText)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(active) { product in
                    productPickerRow(product: product)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(TinkaColor.cardStroke))
    }

    @ViewBuilder
    private func productPickerRow(product: CatalogProduct) -> some View {
        let existingIdx = selectedItems.firstIndex { $0.productId == product.id }
        let qty = existingIdx.map { selectedItems[$0].qty } ?? 0
        HStack(spacing: 12) {
            Text(product.emoji).font(.system(size: 22))
            Text(product.name).font(.tinka(14, weight: .medium)).foregroundColor(TinkaColor.darkNavy)
            Spacer()
            Text("Bs.\(product.price, specifier: "%.0f")").font(.tinka(12)).foregroundColor(TinkaColor.subtleText)
            HStack(spacing: 8) {
                Button {
                    withAnimation {
                        if let idx = existingIdx {
                            if selectedItems[idx].qty > 1 { selectedItems[idx].qty -= 1 }
                            else { selectedItems.remove(at: idx) }
                        }
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(qty > 0 ? TinkaColor.red : Color.gray.opacity(0.3))
                        .font(.system(size: 22))
                }
                .disabled(qty == 0)

                Text("\(qty)").font(.tinka(15, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                    .frame(width: 22)

                Button {
                    withAnimation {
                        if let idx = existingIdx {
                            selectedItems[idx].qty += 1
                        } else {
                            selectedItems.append(ComboItem(productId: product.id, productName: product.name, qty: 1, unitPrice: product.price))
                        }
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(LinearGradient.tinkaPrimary)
                        .font(.system(size: 22))
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var priceSection: some View {
        VStack(spacing: 12) {
            if regularTotal > 0 {
                HStack {
                    Text("Precio normal:").font(.tinka(14)).foregroundColor(TinkaColor.subtleText)
                    Spacer()
                    Text("Bs. \(regularTotal, specifier: "%.0f")").font(.tinka(14)).foregroundColor(TinkaColor.subtleText)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Precio del combo (Bs.)").font(.tinka(13, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
                HStack {
                    Text("Bs.").font(.tinka(16, weight: .bold)).foregroundColor(TinkaColor.magenta)
                    TextField("0", text: $finalPriceText)
                        .font(.tinka(22, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                        .keyboardType(.decimalPad)
                }
                .padding(14)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(TinkaColor.cardStroke))
            }
            if let fp = Double(finalPriceText), regularTotal > 0, regularTotal > fp {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(TinkaColor.green)
                    Text("Ahorro de Bs. \(regularTotal - fp, specifier: "%.0f") para el cliente")
                        .font(.tinka(13, weight: .semibold)).foregroundColor(TinkaColor.green)
                }
                .padding(10)
                .background(TinkaColor.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(TinkaColor.cardStroke))
    }

    private func save() {
        guard let price = Double(finalPriceText) else { return }
        isSaving = true
        let c = ProductCombo(
            id: combo?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            items: selectedItems,
            finalPrice: price,
            emoji: emoji
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if isEditing { state.updateCombo(c) } else { state.addCombo(c) }
            isSaving = false
            dismiss()
        }
    }
}

#Preview { ComboFormSheet(combo: nil).environmentObject(AppState.shared) }
