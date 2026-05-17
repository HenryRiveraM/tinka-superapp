import SwiftUI
import Combine

// MARK: - Models

struct SaleItem: Identifiable, Codable {
    let id: UUID
    let date: Date
    let products: [SaleProduct]
    let total: Double
    let channel: SaleChannel

    init(id: UUID = UUID(), date: Date, products: [SaleProduct], total: Double, channel: SaleChannel) {
        self.id = id; self.date = date; self.products = products; self.total = total; self.channel = channel
    }
}

struct SaleProduct: Identifiable, Codable {
    let id: UUID
    let name: String
    let qty: Int
    let price: Double
    var subtotal: Double { Double(qty) * price }

    init(id: UUID = UUID(), name: String, qty: Int, price: Double) {
        self.id = id; self.name = name; self.qty = qty; self.price = price
    }
}

enum SaleChannel: String, Codable {
    case manual, voice, quick
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date

    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id; self.text = text; self.isUser = isUser; self.timestamp = timestamp
    }
}

// MARK: - Catalog Product

struct CatalogProduct: Identifiable, Codable {
    let id: UUID
    var name: String
    var price: Double
    var category: String
    var emoji: String
    var description: String
    var isActive: Bool
    /// User-defined voice aliases, e.g. ["silpancho", "silpanchos", "silpacho"]
    var aliases: [String]

    init(id: UUID = UUID(), name: String, price: Double, category: String,
         emoji: String, description: String = "", isActive: Bool = true, aliases: [String] = []) {
        self.id = id; self.name = name; self.price = price; self.category = category
        self.emoji = emoji; self.description = description; self.isActive = isActive
        self.aliases = aliases
    }

    // All terms Tinka uses to recognize this product by voice
    var allVoiceTerms: [String] {
        var terms: [String] = []
        let base = VoiceNormalizer.normalize(name)
        terms.append(base)
        terms.append(contentsOf: VoiceNormalizer.plurals(of: base))
        for alias in aliases {
            let a = VoiceNormalizer.normalize(alias)
            terms.append(a)
            terms.append(contentsOf: VoiceNormalizer.plurals(of: a))
        }
        return terms.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}

// MARK: - Combo

struct ProductCombo: Identifiable, Codable {
    let id: UUID
    var name: String
    var items: [ComboItem]
    var finalPrice: Double
    var emoji: String
    var isActive: Bool
    var aliases: [String]

    init(id: UUID = UUID(), name: String, items: [ComboItem], finalPrice: Double,
         emoji: String = "🎁", isActive: Bool = true, aliases: [String] = []) {
        self.id = id; self.name = name; self.items = items; self.finalPrice = finalPrice
        self.emoji = emoji; self.isActive = isActive; self.aliases = aliases
    }

    var regularPrice: Double { items.reduce(0) { $0 + $1.totalPrice } }
    var saving: Double { regularPrice - finalPrice }
}

struct ComboItem: Identifiable, Codable {
    let id: UUID
    var productId: UUID
    var productName: String
    var qty: Int
    var unitPrice: Double
    var totalPrice: Double { Double(qty) * unitPrice }

    init(id: UUID = UUID(), productId: UUID, productName: String, qty: Int, unitPrice: Double) {
        self.id = id; self.productId = productId; self.productName = productName; self.qty = qty; self.unitPrice = unitPrice
    }
}

// MARK: - Product Catalog (legacy compatibility)

enum ProductCatalog {
    static var prices: [String: Double] {
        let products = AppState.shared.catalogProducts.filter { $0.isActive }
        var dict: [String: Double] = [:]
        for p in products { dict[p.name] = p.price }
        return dict
    }

    static var quickProducts: [(name: String, emoji: String, color: Color)] {
        AppState.shared.catalogProducts.filter { $0.isActive }.prefix(4).map { p in
            (p.name, p.emoji, categoryColor(p.category))
        }
    }

    static func categoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "bebida", "bebidas": return TinkaColor.deepBlue
        case "comida rápida", "snack": return TinkaColor.magenta
        case "plato", "almuerzo": return TinkaColor.royalPurple
        case "especial": return Color(hex: "E97316")
        default: return TinkaColor.deepBlue
        }
    }
}

// MARK: - AppState

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var sales: [SaleItem] = []
    @Published var chatMessages: [ChatMessage] = []
    @Published var catalogProducts: [CatalogProduct] = []
    @Published var combos: [ProductCombo] = []
    @Published var isLoadingData = false

    init() {
        loadLocal()
    }

    // MARK: - Load from Supabase (call after login)
    func loadFromSupabase() async {
        await MainActor.run { isLoadingData = true }
        let svc = TinkaDataService.shared
        async let prods = (try? svc.fetchProducts()) ?? []
        async let combosVal = (try? svc.fetchCombos()) ?? []
        async let salesVal = (try? svc.fetchSales()) ?? []
        async let chat = (try? svc.fetchChatMessages()) ?? []
        let (p, c, s, ch) = await (prods, combosVal, salesVal, chat)
        await MainActor.run {
            if !p.isEmpty { catalogProducts = p }
            if !c.isEmpty { combos = c }
            sales = s
            if !ch.isEmpty { chatMessages = ch }
            isLoadingData = false
        }
    }

    // MARK: - Clear on sign out
    func clearAll() {
        sales = []; chatMessages = []; catalogProducts = []; combos = []
        UserDefaults.standard.removeObject(forKey: "tinka_sales_v2")
        UserDefaults.standard.removeObject(forKey: "tinka_chat_v2")
        UserDefaults.standard.removeObject(forKey: "tinka_catalog_v1")
        UserDefaults.standard.removeObject(forKey: "tinka_combos_v1")
    }

    // MARK: - Local fallback
    private func loadLocal() {
        if let d = UserDefaults.standard.data(forKey: "tinka_catalog_v1"),
           let v = try? JSONDecoder().decode([CatalogProduct].self, from: d) { catalogProducts = v }
        if let d = UserDefaults.standard.data(forKey: "tinka_combos_v1"),
           let v = try? JSONDecoder().decode([ProductCombo].self, from: d) { combos = v }
        if let d = UserDefaults.standard.data(forKey: "tinka_sales_v2"),
           let v = try? JSONDecoder().decode([SaleItem].self, from: d) { sales = v }
        if let d = UserDefaults.standard.data(forKey: "tinka_chat_v2"),
           let v = try? JSONDecoder().decode([ChatMessage].self, from: d) { chatMessages = v }
    }

    // MARK: - Computed properties

    var todaySales: Double {
        sales.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.total }
    }

    var todaySaleCount: Int {
        sales.filter { Calendar.current.isDateInToday($0.date) }.count
    }

    var weekSales: Double {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sales.filter { $0.date >= start }.reduce(0) { $0 + $1.total }
    }

    var weekSaleCount: Int {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sales.filter { $0.date >= start }.count
    }

    var monthSales: Double {
        let start = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return sales.filter { $0.date >= start }.reduce(0) { $0 + $1.total }
    }

    var utilityEstimate: Double { weekSales * 0.35 }

    var averageTicket: Double {
        let week = salesForPeriod(.week)
        guard !week.isEmpty else { return 0 }
        return week.reduce(0) { $0 + $1.total } / Double(week.count)
    }

    var topProduct: String {
        var counts: [String: Int] = [:]
        for sale in sales {
            for p in sale.products { counts[p.name, default: 0] += p.qty }
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? catalogProducts.first?.name ?? "Salteña"
    }

    var topProductsSummary: [(name: String, qty: Int)] {
        var counts: [String: Int] = [:]
        for sale in sales {
            for p in sale.products { counts[p.name, default: 0] += p.qty }
        }
        return counts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }

    var financialStatus: String {
        if todaySales >= 300 { return "Saludable" }
        if todaySales >= 100 { return "Regular" }
        return "Riesgo"
    }

    var financialStatusColor: Color {
        if todaySales >= 300 { return TinkaColor.green }
        if todaySales >= 100 { return TinkaColor.yellow }
        return TinkaColor.red
    }

    var tinkaScore: Int {
        let salesScore = min(Int(weekSales / 50), 30)
        let cal = Calendar.current
        var activeDays = Set<Int>()
        for sale in sales {
            let day = cal.ordinality(of: .day, in: .era, for: sale.date) ?? 0
            activeDays.insert(day)
        }
        let consistencyScore = min(activeDays.count * 3, 20)
        let utilityScore = min(Int(utilityEstimate / 40), 15)
        return min(40 + salesScore + consistencyScore + utilityScore, 100)
    }

    var dailyTrend: [(day: String, value: Double)] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "es_BO")
        fmt.dateFormat = "E"
        return (0..<7).reversed().map { offset -> (String, Double) in
            let date = cal.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let label = String(fmt.string(from: date).prefix(2)).capitalized
            let total = sales.filter { cal.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.total }
            return (label, total)
        }
    }

    var businessContextForAI: String {
        let topProds = topProductsSummary.map { "\($0.name): \($0.qty) unidades" }.joined(separator: ", ")
        let activeProducts = catalogProducts.filter { $0.isActive }.map { "\($0.name) (Bs. \($0.price))" }.joined(separator: ", ")
        let activeCombos = combos.filter { $0.isActive }.map { "\($0.name) (Bs. \($0.finalPrice))" }.joined(separator: ", ")
        return """
Contexto del negocio de Doña María:
- Ventas hoy: Bs. \(Int(todaySales)) (\(todaySaleCount) ventas)
- Ventas esta semana: Bs. \(Int(weekSales)) (\(weekSaleCount) ventas)
- Ventas este mes: Bs. \(Int(monthSales))
- Utilidad estimada (35%): Bs. \(Int(utilityEstimate))
- Ticket promedio: Bs. \(Int(averageTicket))
- Producto estrella: \(topProduct)
- Top productos vendidos: \(topProds.isEmpty ? "sin datos" : topProds)
- Estado financiero: \(financialStatus)
- Tinka Score: \(tinkaScore)/100
- Catálogo activo: \(activeProducts.isEmpty ? "sin productos" : activeProducts)
- Combos activos: \(activeCombos.isEmpty ? "sin combos" : activeCombos)
- Tendencia semanal (últ. 7 días): \(dailyTrend.map { "\($0.day):\(Int($0.value))" }.joined(separator: ", "))
"""
    }

    // MARK: - Actions

    func addSale(_ sale: SaleItem) {
        withAnimation(.spring(response: 0.4)) { sales.insert(sale, at: 0) }
        persistSales()
        Task { try? await TinkaDataService.shared.insertSale(sale) }
    }

    func deleteSale(_ id: UUID) {
        withAnimation { sales.removeAll { $0.id == id } }
        persistSales()
        Task { try? await TinkaDataService.shared.deleteSale(id: id) }
    }

    func salesForPeriod(_ period: AppPeriod) -> [SaleItem] {
        let cal = Calendar.current
        return sales.filter { sale in
            switch period {
            case .today: return cal.isDateInToday(sale.date)
            case .week:
                let start = cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                return sale.date >= start
            case .month:
                let start = cal.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                return sale.date >= start
            }
        }
    }

    func addProduct(_ product: CatalogProduct) {
        withAnimation { catalogProducts.append(product) }
        persistCatalog()
        Task { try? await TinkaDataService.shared.upsertProduct(product) }
    }

    func updateProduct(_ product: CatalogProduct) {
        if let idx = catalogProducts.firstIndex(where: { $0.id == product.id }) {
            withAnimation { catalogProducts[idx] = product }
        }
        persistCatalog()
        Task { try? await TinkaDataService.shared.upsertProduct(product) }
    }

    func deleteProduct(_ id: UUID) {
        withAnimation { catalogProducts.removeAll { $0.id == id } }
        persistCatalog()
        Task { try? await TinkaDataService.shared.deleteProduct(id: id) }
    }

    func toggleProduct(_ id: UUID) {
        if let idx = catalogProducts.firstIndex(where: { $0.id == id }) {
            withAnimation { catalogProducts[idx].isActive.toggle() }
            let updated = catalogProducts[idx]
            persistCatalog()
            Task { try? await TinkaDataService.shared.upsertProduct(updated) }
        }
    }

    func addCombo(_ combo: ProductCombo) {
        withAnimation { combos.append(combo) }
        persistCombos()
        Task { try? await TinkaDataService.shared.upsertCombo(combo) }
    }

    func updateCombo(_ combo: ProductCombo) {
        if let idx = combos.firstIndex(where: { $0.id == combo.id }) {
            withAnimation { combos[idx] = combo }
        }
        persistCombos()
        Task { try? await TinkaDataService.shared.upsertCombo(combo) }
    }

    func deleteCombo(_ id: UUID) {
        withAnimation { combos.removeAll { $0.id == id } }
        persistCombos()
        Task { try? await TinkaDataService.shared.deleteCombo(id: id) }
    }

    func addChatMessage(_ msg: ChatMessage) {
        chatMessages.append(msg)
        persistChat()
        Task { try? await TinkaDataService.shared.insertChatMessage(msg) }
    }

    // MARK: - Persistence (local fallback)
    func persistSales() {
        guard let data = try? JSONEncoder().encode(sales) else { return }
        UserDefaults.standard.set(data, forKey: "tinka_sales_v2")
    }

    func persistChat() {
        guard let data = try? JSONEncoder().encode(chatMessages) else { return }
        UserDefaults.standard.set(data, forKey: "tinka_chat_v2")
    }

    func persistCatalog() {
        guard let data = try? JSONEncoder().encode(catalogProducts) else { return }
        UserDefaults.standard.set(data, forKey: "tinka_catalog_v1")
    }

    func persistCombos() {
        guard let data = try? JSONEncoder().encode(combos) else { return }
        UserDefaults.standard.set(data, forKey: "tinka_combos_v1")
    }
}

// MARK: - Period enum

enum AppPeriod: String, CaseIterable {
    case today = "Hoy", week = "Semana", month = "Mes"
}

// MARK: - Seed Data

enum SeedData {
    static var defaultSales: [SaleItem] {
        let cal = Calendar.current
        func ago(_ h: Int) -> Date { cal.date(byAdding: .hour, value: -h, to: Date()) ?? Date() }
        return [
            SaleItem(date: ago(1),  products: [.init(name: "Salteña", qty: 5, price: 5), .init(name: "Refresco", qty: 3, price: 4)],  total: 37, channel: .voice),
            SaleItem(date: ago(2),  products: [.init(name: "Almuerzo", qty: 2, price: 15)], total: 30, channel: .manual),
            SaleItem(date: ago(3),  products: [.init(name: "Pique Macho", qty: 1, price: 35), .init(name: "Refresco", qty: 2, price: 4)], total: 43, channel: .quick),
            SaleItem(date: ago(26), products: [.init(name: "Salteña", qty: 8, price: 5)], total: 40, channel: .manual),
            SaleItem(date: ago(27), products: [.init(name: "Almuerzo", qty: 3, price: 15)], total: 45, channel: .quick),
            SaleItem(date: ago(50), products: [.init(name: "Salteña", qty: 10, price: 5), .init(name: "Refresco", qty: 5, price: 4)], total: 70, channel: .voice)
        ]
    }

    static var defaultProducts: [CatalogProduct] {[
        CatalogProduct(name: "Salteña", price: 5, category: "Snack", emoji: "🫓",
                       description: "Salteña tradicional boliviana",
                       aliases: ["salteña", "salteñas", "saltena", "saltenas"]),
        CatalogProduct(name: "Refresco", price: 4, category: "Bebida", emoji: "🥤",
                       description: "Bebida fría",
                       aliases: ["refresco", "refrescos", "fresco", "frescos", "jugo", "jugos"]),
        CatalogProduct(name: "Almuerzo", price: 15, category: "Plato", emoji: "🍱",
                       description: "Menú del día completo",
                       aliases: ["almuerzo", "almuerzos", "menu", "menú", "plato"]),
        CatalogProduct(name: "Pique Macho", price: 35, category: "Especial", emoji: "🥩",
                       description: "Pique macho tradicional",
                       aliases: ["pique", "piques", "pique macho", "piques machos", "piquez"]),
        CatalogProduct(name: "Coca Cola", price: 12, category: "Bebida", emoji: "🥫",
                       description: "Gaseosa personal",
                       aliases: ["coca cola", "coca", "cocas", "cola", "gaseosa", "gaseosas"]),
    ]}

    static var defaultCombos: [ProductCombo] {
        let prods = defaultProducts
        let salteña = prods[0]; let refresco = prods[1]; let almuerzo = prods[2]
        return [
            ProductCombo(
                name: "Combo Desayuno",
                items: [
                    ComboItem(productId: salteña.id, productName: salteña.name, qty: 2, unitPrice: salteña.price),
                    ComboItem(productId: refresco.id, productName: refresco.name, qty: 1, unitPrice: refresco.price)
                ],
                finalPrice: 12,
                emoji: "🌅"
            ),
            ProductCombo(
                name: "Combo Ejecutivo",
                items: [
                    ComboItem(productId: almuerzo.id, productName: almuerzo.name, qty: 1, unitPrice: almuerzo.price),
                    ComboItem(productId: refresco.id, productName: refresco.name, qty: 1, unitPrice: refresco.price)
                ],
                finalPrice: 17,
                emoji: "💼"
            )
        ]
    }
}
