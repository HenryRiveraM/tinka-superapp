import SwiftUI

struct ProductFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    let product: CatalogProduct?
    let onSave: (CatalogProduct) -> Void

    @State private var name: String = ""
    @State private var priceText: String = ""
    @State private var category: String = "Comida"
    @State private var emoji: String = "🍽️"
    @State private var description: String = ""
    @State private var isActive: Bool = true
    @State private var showEmojiPicker = false
    @State private var isSaving = false

    private let categories = ["Comida", "Bebida", "Snack", "Plato", "Especial", "Postre", "Desayuno", "Otro"]
    private let quickEmojis = ["🫓","🥤","🍱","🥩","🥫","☕","🍔","🍕","🌮","🥗","🍜","🍰","🧁","🥞","🍟","🌯","🥙","🫔","🧆","🥚"]

    var isEditing: Bool { product != nil }
    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && Double(priceText) != nil }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.tinkaSoftBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        emojiSection
                        formCard
                    }
                    .padding(18)
                }
            }
            .navigationTitle(isEditing ? "Editar Producto" : "Nuevo Producto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(TinkaColor.subtleText)
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
            if let p = product {
                name = p.name; priceText = String(format: "%.0f", p.price)
                category = p.category; emoji = p.emoji
                description = p.description; isActive = p.isActive
            }
        }
    }

    private var emojiSection: some View {
        VStack(spacing: 12) {
            Button { withAnimation { showEmojiPicker.toggle() } } label: {
                ZStack {
                    Circle().fill(LinearGradient.tinkaPrimary.opacity(0.12)).frame(width: 90, height: 90)
                    Text(emoji).font(.system(size: 44))
                }
            }
            Text("Toca para cambiar el icono").font(.tinka(12)).foregroundColor(TinkaColor.subtleText)
            if showEmojiPicker {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 10) {
                    ForEach(quickEmojis, id: \.self) { e in
                        Button { emoji = e; showEmojiPicker = false } label: {
                            Text(e).font(.system(size: 26))
                                .frame(width: 36, height: 36)
                                .background(emoji == e ? TinkaColor.magenta.opacity(0.15) : Color.clear)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    private var formCard: some View {
        VStack(spacing: 16) {
            FormFieldView(label: "Nombre del producto", placeholder: "Ej: Salteña, Hamburguesa...", text: $name)

            VStack(alignment: .leading, spacing: 6) {
                Text("Precio (Bs.)").font(.tinka(13, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
                HStack {
                    Text("Bs.").font(.tinka(16, weight: .bold)).foregroundColor(TinkaColor.deepBlue)
                    TextField("0", text: $priceText)
                        .font(.tinka(20, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                        .keyboardType(.decimalPad)
                }
                .padding(14)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(TinkaColor.cardStroke))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Categoría").font(.tinka(13, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            Button { withAnimation { category = cat } } label: {
                                Text(cat)
                                    .font(.tinka(13, weight: category == cat ? .bold : .medium))
                                    .foregroundColor(category == cat ? .white : TinkaColor.darkNavy)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(category == cat ? AnyShapeStyle(LinearGradient.tinkaPrimary) : AnyShapeStyle(Color.white.opacity(0.8)))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(TinkaColor.cardStroke))
                            }
                        }
                    }
                }
            }

            FormFieldView(label: "Descripción (opcional)", placeholder: "Describe el producto...", text: $description)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Producto activo").font(.tinka(15, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
                    Text("Aparece en ventas rápidas y voz").font(.tinka(12)).foregroundColor(TinkaColor.subtleText)
                }
                Spacer()
                Toggle("", isOn: $isActive)
                    .tint(TinkaColor.deepBlue)
            }
            .padding(14)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(TinkaColor.cardStroke))
        }
        .padding(18)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(TinkaColor.cardStroke))
    }

    private func save() {
        guard let price = Double(priceText) else { return }
        isSaving = true
        let trimName = name.trimmingCharacters(in: .whitespaces)
        let p = CatalogProduct(
            id: product?.id ?? UUID(),
            name: trimName, price: price, category: category,
            emoji: emoji, description: description, isActive: isActive
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSave(p)
            isSaving = false
            dismiss()
        }
    }
}

struct FormFieldView: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.tinka(13, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
            TextField(placeholder, text: $text)
                .font(.tinka(15)).foregroundColor(TinkaColor.darkNavy)
                .padding(14)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(TinkaColor.cardStroke))
        }
    }
}

#Preview { ProductFormSheet(product: nil) { _ in }.environmentObject(AppState.shared) }
