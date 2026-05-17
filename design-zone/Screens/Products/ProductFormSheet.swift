import SwiftUI

struct ProductFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var state: AppState
    let product: CatalogProduct?
    let onSave: (CatalogProduct) -> Void

    @State private var name = ""
    @State private var priceText = ""
    @State private var category = "Comida"
    @State private var emoji = "🍽️"
    @State private var description = ""
    @State private var isActive = true
    @State private var aliasesText = ""
    @State private var showEmojiPicker = false
    @State private var isSaving = false

    private let categories = ["Comida", "Bebida", "Snack", "Plato", "Especial", "Postre", "Desayuno", "Otro"]
    private let quickEmojis = ["🫓","🥤","🍱","🥩","🥫","☕","🍔","🍕","🌮","🥗","🍜","🍰","🧁","🥞","🍟","🌯","🥙","🫔","🧆","🥚","🍦","🥧","🫕","🥘","🍲"]

    var isEditing: Bool { product != nil }
    var parsedPrice: Double? { Double(priceText.replacingOccurrences(of: ",", with: ".")) }
    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && parsedPrice != nil }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.tinkaSoftBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        emojiSection
                        formFields
                    }
                    .padding(18)
                }
            }
            .navigationTitle(isEditing ? "Editar Producto" : "Nuevo Producto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }.foregroundColor(TinkaColor.subtleText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Guardando..." : "Guardar") { save() }
                        .font(.tinka(15, weight: .bold))
                        .foregroundStyle(isValid ? AnyShapeStyle(LinearGradient.tinkaPrimary) : AnyShapeStyle(Color.gray))
                        .disabled(!isValid || isSaving)
                }
            }
        }
        .onAppear { prefill() }
    }

    private func prefill() {
        guard let p = product else { return }
        name = p.name; priceText = String(format: "%.0f", p.price)
        category = p.category; emoji = p.emoji
        description = p.description; isActive = p.isActive
        aliasesText = p.aliases.joined(separator: ", ")
    }

    // MARK: - Emoji Section
    private var emojiSection: some View {
        VStack(spacing: 10) {
            Button { withAnimation { showEmojiPicker.toggle() } } label: {
                ZStack {
                    Circle().fill(TinkaColor.royalPurple.opacity(0.1)).frame(width: 90, height: 90)
                    Text(emoji).font(.system(size: 44))
                }
            }
            Text("Toca para cambiar icono").font(.tinka(12)).foregroundColor(TinkaColor.subtleText)

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

    // MARK: - Form Fields
    private var formFields: some View {
        VStack(spacing: 16) {
            catalogFormField(label: "Nombre del producto", placeholder: "Ej: Hamburguesa, Café...", text: $name)

            // Price field
            VStack(alignment: .leading, spacing: 6) {
                Text("Precio (Bs.)").font(.tinka(13, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
                HStack {
                    Text("Bs.").font(.tinka(16, weight: .bold)).foregroundColor(TinkaColor.deepBlue)
                    TextField("0", text: $priceText).font(.tinka(20, weight: .bold))
                        .foregroundColor(TinkaColor.darkNavy).keyboardType(.decimalPad)
                }
                .padding(14)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(TinkaColor.cardStroke))
            }

            // Category chips
            VStack(alignment: .leading, spacing: 8) {
                Text("Categoría").font(.tinka(13, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            Button { withAnimation { category = cat } } label: {
                                Text(cat)
                                    .font(.tinka(13, weight: category == cat ? .bold : .medium))
                                    .foregroundColor(category == cat ? .white : TinkaColor.darkNavy)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(category == cat
                                        ? AnyShapeStyle(LinearGradient.tinkaPrimary)
                                        : AnyShapeStyle(Color.white.opacity(0.8)))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(TinkaColor.cardStroke))
                            }
                        }
                    }
                }
            }

            catalogFormField(label: "Descripción (opcional)", placeholder: "Describe el producto...", text: $description)

            // Voice aliases field
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "waveform").font(.system(size: 12)).foregroundColor(TinkaColor.magenta)
                    Text("Palabras para reconocer por voz").font(.tinka(13, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
                }
                TextField("silpancho, silpanchos, silpacho...", text: $aliasesText)
                    .font(.tinka(14)).foregroundColor(TinkaColor.darkNavy)
                    .padding(14)
                    .background(Color.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(TinkaColor.magenta.opacity(0.3)))
                Text("Separadas por coma. Tinka usará estas palabras para detectar este producto.")
                    .font(.tinka(11)).foregroundColor(TinkaColor.subtleText).padding(.horizontal, 2)
            }

            // Active toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Producto activo").font(.tinka(15, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
                    Text("Visible en ventas rápidas y voz").font(.tinka(12)).foregroundColor(TinkaColor.subtleText)
                }
                Spacer()
                Toggle("", isOn: $isActive).tint(TinkaColor.deepBlue)
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
        guard let price = parsedPrice else { return }
        isSaving = true
        let parsedAliases = aliasesText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let p = CatalogProduct(
            id: product?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            price: price, category: category,
            emoji: emoji, description: description,
            isActive: isActive, aliases: parsedAliases
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onSave(p); isSaving = false; dismiss()
        }
    }
}

// Shared form field used in both product and combo forms
struct catalogFormField: View {
    let label: String; let placeholder: String
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
