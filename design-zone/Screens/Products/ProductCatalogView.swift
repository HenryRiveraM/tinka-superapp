import SwiftUI

struct ProductCatalogView: View {
    @EnvironmentObject var state: AppState
    @State private var showAddProduct = false
    @State private var showAddCombo = false
    @State private var editingProduct: CatalogProduct? = nil
    @State private var editingCombo: ProductCombo? = nil
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            LinearGradient.tinkaSoftBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                segmentPicker
                    .padding(.horizontal, 18)
                    .padding(.top, 4)
                if selectedTab == 0 {
                    productList
                } else {
                    comboList
                }
                Color.clear.frame(height: 110)
            }
        }
        .sheet(isPresented: $showAddProduct) {
            ProductFormSheet(product: nil) { p in state.addProduct(p) }
        }
        .sheet(item: $editingProduct) { p in
            ProductFormSheet(product: p) { updated in state.updateProduct(updated) }
        }
        .sheet(isPresented: $showAddCombo) {
            ComboFormSheet(combo: nil)
        }
        .sheet(item: $editingCombo) { c in
            ComboFormSheet(combo: c)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Catálogo").font(.tinka(26, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                Text("\(state.catalogProducts.filter { $0.isActive }.count) productos · \(state.combos.filter { $0.isActive }.count) combos")
                    .font(.tinka(13)).foregroundColor(TinkaColor.subtleText)
            }
            Spacer()
            Button { selectedTab == 0 ? (showAddProduct = true) : (showAddCombo = true) } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(LinearGradient.tinkaPrimary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    private var segmentPicker: some View {
        HStack(spacing: 0) {
            ForEach(["Productos", "Combos"].indices, id: \.self) { i in
                let label = ["Productos", "Combos"][i]
                Button { withAnimation(.spring(response: 0.3)) { selectedTab = i } } label: {
                    Text(label)
                        .font(.tinka(14, weight: selectedTab == i ? .bold : .medium))
                        .foregroundColor(selectedTab == i ? .white : TinkaColor.subtleText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
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
            .padding(.horizontal, 18)
            .padding(.top, 14)
        }
    }

    @ViewBuilder
    private var productsByCategory: some View {
        let grouped = Dictionary(grouping: state.catalogProducts) { $0.category }
        let sortedKeys = grouped.keys.sorted()
        ForEach(sortedKeys, id: \.self) { category in
            if let items = grouped[category] {
                categorySection(title: category, items: items)
            }
        }
    }

    @ViewBuilder
    private func categorySection(title: String, items: [CatalogProduct]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.tinka(11, weight: .bold))
                .foregroundColor(TinkaColor.subtleText)
                .padding(.horizontal, 4)
            ForEach(items) { product in
                ProductRowCard(product: product,
                    onEdit: { editingProduct = product },
                    onToggle: { state.toggleProduct(product.id) },
                    onDelete: { state.deleteProduct(product.id) }
                )
            }
        }
    }

    private var emptyProductsState: some View {
        VStack(spacing: 16) {
            Text("🛍️").font(.system(size: 52))
            Text("Sin productos aún").font(.tinka(18, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
            Text("Toca + para agregar tu primer producto al catálogo")
                .font(.tinka(14)).foregroundColor(TinkaColor.subtleText).multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    // MARK: - Combo List
    private var comboList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(state.combos) { combo in
                    ComboRowCard(combo: combo,
                        onEdit: { editingCombo = combo },
                        onDelete: { state.deleteCombo(combo.id) }
                    )
                }
                if state.combos.isEmpty { emptyCombosState }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
        }
    }

    private var emptyCombosState: some View {
        VStack(spacing: 16) {
            Text("🎁").font(.system(size: 52))
            Text("Sin combos aún").font(.tinka(18, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
            Text("Crea combos para ofrecer promociones especiales a tus clientes")
                .font(.tinka(14)).foregroundColor(TinkaColor.subtleText).multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
}

// MARK: - Product Row Card

struct ProductRowCard: View {
    let product: CatalogProduct
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                let bgColor = product.isActive ? TinkaColor.royalPurple.opacity(0.12) : Color.gray.opacity(0.1)
                Circle().fill(bgColor).frame(width: 50, height: 50)
                Text(product.emoji).font(.system(size: 24))
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(product.name)
                        .font(.tinka(15, weight: .semibold))
                        .foregroundColor(product.isActive ? TinkaColor.darkNavy : TinkaColor.subtleText)
                    if !product.isActive {
                        Text("Inactivo").font(.tinka(10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.gray).clipShape(Capsule())
                    }
                }
                if !product.description.isEmpty {
                    Text(product.description).font(.tinka(12)).foregroundColor(TinkaColor.subtleText).lineLimit(1)
                }
            }
            Spacer()
            Text("Bs. \(product.price, specifier: "%.0f")")
                .font(.tinka(16, weight: .bold))
                .foregroundColor(TinkaColor.deepBlue)
        }
        .padding(14)
        .background(Color.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(TinkaColor.cardStroke))
        .opacity(product.isActive ? 1 : 0.65)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { onDelete() } label: {
                Label("Eliminar", systemImage: "trash")
            }
            Button { onEdit() } label: {
                Label("Editar", systemImage: "pencil")
            }
            .tint(TinkaColor.deepBlue)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button { onToggle() } label: {
                Label(product.isActive ? "Desactivar" : "Activar",
                      systemImage: product.isActive ? "pause.circle" : "play.circle")
            }
            .tint(product.isActive ? TinkaColor.yellow : TinkaColor.green)
        }
    }
}

// MARK: - Combo Row Card

struct ComboRowCard: View {
    let combo: ProductCombo
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                        Text("Normal Bs. \(combo.regularPrice, specifier: "%.0f")")
                            .font(.tinka(11)).foregroundColor(TinkaColor.subtleText)
                            .strikethrough(true, color: TinkaColor.subtleText)
                    }
                }
            }
            Divider()
            HStack(spacing: 8) {
                ForEach(combo.items) { item in
                    HStack(spacing: 4) {
                        Text("\(item.qty)x").font(.tinka(12, weight: .bold)).foregroundColor(TinkaColor.royalPurple)
                        Text(item.productName).font(.tinka(12)).foregroundColor(TinkaColor.darkNavy)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(TinkaColor.royalPurple.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(TinkaColor.cardStroke))
        .shadow(color: TinkaColor.royalPurple.opacity(0.06), radius: 10, y: 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { onDelete() } label: {
                Label("Eliminar", systemImage: "trash")
            }
            Button { onEdit() } label: {
                Label("Editar", systemImage: "pencil")
            }
            .tint(TinkaColor.deepBlue)
        }
    }
}

#Preview { ProductCatalogView().environmentObject(AppState.shared) }
