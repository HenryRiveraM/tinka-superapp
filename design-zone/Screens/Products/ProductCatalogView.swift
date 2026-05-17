import SwiftUI

struct ProductCatalogView: View {
    @EnvironmentObject var state: AppState
    @State private var showAddProduct = false
    @State private var showAddCombo = false
    @State private var editingProduct: CatalogProduct? = nil
    @State private var editingCombo: ProductCombo? = nil
    @State private var selectedTab = 0
    @State private var deleteProductAlert: CatalogProduct? = nil
    @State private var deleteComboAlert: ProductCombo? = nil

    var body: some View {
        ZStack {
            LinearGradient.tinkaSoftBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                catalogHeader
                segmentPicker
                    .padding(.horizontal, 18).padding(.vertical, 10)
                if selectedTab == 0 { productList } else { comboList }
                Color.clear.frame(height: 110)
            }
        }
        .sheet(isPresented: $showAddProduct) {
            ProductFormSheet(product: nil) { p in state.addProduct(p) }
                .environmentObject(state)
        }
        .sheet(item: $editingProduct) { p in
            ProductFormSheet(product: p) { updated in state.updateProduct(updated) }
                .environmentObject(state)
        }
        .sheet(isPresented: $showAddCombo) {
            ComboFormSheet(combo: nil).environmentObject(state)
        }
        .sheet(item: $editingCombo) { c in
            ComboFormSheet(combo: c).environmentObject(state)
        }
        .alert("Eliminar producto", isPresented: Binding(
            get: { deleteProductAlert != nil },
            set: { if !$0 { deleteProductAlert = nil } }
        )) {
            Button("Eliminar", role: .destructive) {
                if let p = deleteProductAlert { state.deleteProduct(p.id) }
                deleteProductAlert = nil
            }
            Button("Cancelar", role: .cancel) { deleteProductAlert = nil }
        } message: {
            Text("¿Eliminar \"\(deleteProductAlert?.name ?? "")\" del catálogo? Esta acción no se puede deshacer.")
        }
        .alert("Eliminar combo", isPresented: Binding(
            get: { deleteComboAlert != nil },
            set: { if !$0 { deleteComboAlert = nil } }
        )) {
            Button("Eliminar", role: .destructive) {
                if let c = deleteComboAlert { state.deleteCombo(c.id) }
                deleteComboAlert = nil
            }
            Button("Cancelar", role: .cancel) { deleteComboAlert = nil }
        } message: {
            Text("¿Eliminar el combo \"\(deleteComboAlert?.name ?? "")\"?")
        }
    }

    // MARK: - Header
    private var catalogHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Catálogo").font(.tinka(26, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                let activeP = state.catalogProducts.filter { $0.isActive }.count
                let activeC = state.combos.filter { $0.isActive }.count
                Text("\(activeP) productos · \(activeC) combos activos")
                    .font(.tinka(13)).foregroundColor(TinkaColor.subtleText)
            }
            Spacer()
            Button {
                if selectedTab == 0 { showAddProduct = true } else { showAddCombo = true }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                    Text("Nuevo").font(.tinka(14, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(LinearGradient.tinkaPrimary)
                .clipShape(Capsule())
                .shadow(color: TinkaColor.magenta.opacity(0.3), radius: 8, y: 4)
            }
        }
        .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 4)
    }

    // MARK: - Segment
    private var segmentPicker: some View {
        HStack(spacing: 0) {
            ForEach(0..<2) { i in
                let label = i == 0 ? "Productos" : "Combos"
                Button { withAnimation(.spring(response: 0.3)) { selectedTab = i } } label: {
                    Text(label)
                        .font(.tinka(14, weight: selectedTab == i ? .bold : .medium))
                        .foregroundColor(selectedTab == i ? .white : TinkaColor.subtleText)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(selectedTab == i ? AnyShapeStyle(LinearGradient.tinkaPrimary) : AnyShapeStyle(Color.clear))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(TinkaColor.cardStroke))
    }

    // MARK: - Product List
    private var productList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                if state.catalogProducts.isEmpty {
                    emptyProductsState
                } else {
                    productsByCategory
                }
            }
            .padding(.horizontal, 18).padding(.top, 4)
        }
    }

    @ViewBuilder
    private var productsByCategory: some View {
        let grouped = Dictionary(grouping: state.catalogProducts) { $0.category }
        ForEach(grouped.keys.sorted(), id: \.self) { cat in
            if let items = grouped[cat] {
                VStack(alignment: .leading, spacing: 8) {
                    Text(cat.uppercased())
                        .font(.tinka(11, weight: .bold))
                        .foregroundColor(TinkaColor.subtleText)
                        .padding(.horizontal, 4)
                    ForEach(items) { product in
                        ProductRowCard(
                            product: product,
                            onEdit: { editingProduct = product },
                            onToggle: { state.toggleProduct(product.id) },
                            onDelete: { deleteProductAlert = product }
                        )
                    }
                }
            }
        }
    }

    private var emptyProductsState: some View {
        VStack(spacing: 16) {
            Text("🛍️").font(.system(size: 52))
            Text("Sin productos aún").font(.tinka(18, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
            Text("Toca **Nuevo** para agregar tu primer producto")
                .font(.tinka(14)).foregroundColor(TinkaColor.subtleText).multilineTextAlignment(.center)
            Button { showAddProduct = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                    Text("Crear primer producto").font(.tinka(15, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(LinearGradient.tinkaPrimary)
                .clipShape(Capsule())
            }
        }
        .padding(.top, 60)
    }

    // MARK: - Combo List
    private var comboList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                if state.combos.isEmpty {
                    emptyCombosState
                } else {
                    ForEach(state.combos) { combo in
                        ComboRowCard(
                            combo: combo,
                            onEdit: { editingCombo = combo },
                            onDelete: { deleteComboAlert = combo }
                        )
                    }
                }
            }
            .padding(.horizontal, 18).padding(.top, 4)
        }
    }

    private var emptyCombosState: some View {
        VStack(spacing: 16) {
            Text("🎁").font(.system(size: 52))
            Text("Sin combos aún").font(.tinka(18, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
            Text("Crea combos para ofrecer promociones especiales")
                .font(.tinka(14)).foregroundColor(TinkaColor.subtleText).multilineTextAlignment(.center)
            Button { showAddCombo = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                    Text("Crear primer combo").font(.tinka(15, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(LinearGradient.tinkaPrimary)
                .clipShape(Capsule())
            }
        }
        .padding(.top, 60)
    }
}

// MARK: - Product Row Card (with visible edit button)

struct ProductRowCard: View {
    let product: CatalogProduct
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            emojiCircle
            productInfo
            Spacer()
            priceAndActions
        }
        .padding(14)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(TinkaColor.cardStroke))
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
        .opacity(product.isActive ? 1 : 0.65)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { onDelete() } label: { Label("Eliminar", systemImage: "trash") }
            Button { onEdit() } label: { Label("Editar", systemImage: "pencil") }.tint(TinkaColor.deepBlue)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button { onToggle() } label: {
                Label(product.isActive ? "Desactivar" : "Activar",
                      systemImage: product.isActive ? "pause.circle" : "play.circle")
            }
            .tint(product.isActive ? TinkaColor.yellow : TinkaColor.green)
        }
    }

    private var emojiCircle: some View {
        ZStack {
            Circle()
                .fill(product.isActive ? TinkaColor.royalPurple.opacity(0.1) : Color.gray.opacity(0.08))
                .frame(width: 50, height: 50)
            Text(product.emoji).font(.system(size: 24))
        }
    }

    private var productInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(product.name)
                    .font(.tinka(15, weight: .semibold))
                    .foregroundColor(product.isActive ? TinkaColor.darkNavy : TinkaColor.subtleText)
                if !product.isActive {
                    Text("Inactivo")
                        .font(.tinka(10, weight: .bold)).foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.gray.opacity(0.6)).clipShape(Capsule())
                }
            }
            if !product.description.isEmpty {
                Text(product.description)
                    .font(.tinka(12)).foregroundColor(TinkaColor.subtleText).lineLimit(1)
            } else {
                Text(product.category)
                    .font(.tinka(11)).foregroundColor(TinkaColor.subtleText.opacity(0.7))
            }
        }
    }

    private var priceAndActions: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("Bs. \(product.price, specifier: "%.0f")")
                .font(.tinka(16, weight: .bold)).foregroundColor(TinkaColor.deepBlue)
            // Visible edit button
            Button(action: onEdit) {
                HStack(spacing: 4) {
                    Image(systemName: "pencil").font(.system(size: 11, weight: .bold))
                    Text("Editar").font(.tinka(11, weight: .semibold))
                }
                .foregroundColor(TinkaColor.royalPurple)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(TinkaColor.royalPurple.opacity(0.1))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(TinkaColor.royalPurple.opacity(0.25)))
            }
        }
    }
}

// MARK: - Combo Row Card (with visible edit button)

struct ComboRowCard: View {
    let combo: ProductCombo
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            comboHeader
            Divider()
            HStack {
                itemChips
                Spacer()
                editDeleteButtons
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(TinkaColor.cardStroke))
        .shadow(color: TinkaColor.royalPurple.opacity(0.06), radius: 10, y: 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { onDelete() } label: { Label("Eliminar", systemImage: "trash") }
            Button { onEdit() } label: { Label("Editar", systemImage: "pencil") }.tint(TinkaColor.deepBlue)
        }
    }

    private var comboHeader: some View {
        HStack {
            Text(combo.emoji).font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text(combo.name).font(.tinka(16, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                if combo.saving > 0 {
                    Text("Ahorro: Bs. \(combo.saving, specifier: "%.0f")")
                        .font(.tinka(11, weight: .semibold)).foregroundColor(TinkaColor.green)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Bs. \(combo.finalPrice, specifier: "%.0f")")
                    .font(.tinka(20, weight: .bold)).foregroundColor(TinkaColor.magenta)
                if combo.saving > 0 {
                    Text("Bs. \(combo.regularPrice, specifier: "%.0f")")
                        .font(.tinka(11)).foregroundColor(TinkaColor.subtleText)
                        .strikethrough(true, color: TinkaColor.subtleText)
                }
            }
        }
    }

    private var itemChips: some View {
        HStack(spacing: 8) {
            ForEach(combo.items) { item in
                Text("\(item.qty)x \(item.productName)")
                    .font(.tinka(12, weight: .medium)).foregroundColor(TinkaColor.royalPurple)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(TinkaColor.royalPurple.opacity(0.08)).clipShape(Capsule())
            }
        }
    }

    private var editDeleteButtons: some View {
        HStack(spacing: 8) {
            Button(action: onEdit) {
                HStack(spacing: 4) {
                    Image(systemName: "pencil").font(.system(size: 11, weight: .bold))
                    Text("Editar").font(.tinka(11, weight: .semibold))
                }
                .foregroundColor(TinkaColor.royalPurple)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(TinkaColor.royalPurple.opacity(0.1)).clipShape(Capsule())
                .overlay(Capsule().stroke(TinkaColor.royalPurple.opacity(0.25)))
            }
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(TinkaColor.red)
                    .padding(7)
                    .background(TinkaColor.red.opacity(0.08)).clipShape(Circle())
                    .overlay(Circle().stroke(TinkaColor.red.opacity(0.2)))
            }
        }
    }
}

#Preview { ProductCatalogView().environmentObject(AppState.shared) }
