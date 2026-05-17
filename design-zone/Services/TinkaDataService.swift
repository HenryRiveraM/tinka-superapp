import Foundation

// MARK: - Tinka Data Service (Supabase REST CRUD)
@MainActor
class TinkaDataService {
    static let shared = TinkaDataService()
    private init() {}

    private var userId: String? { get async { await SupabaseREST.shared.userId } }
    private let rest = SupabaseREST.shared

    // MARK: - Products
    func fetchProducts() async throws -> [CatalogProduct] {
        guard let uid = await userId else { return [] }
        let rows: [DBProduct] = try await rest.select(table: "products",
                                                       filters: ["user_id": uid],
                                                       orderBy: "created_at")
        return rows.map { toCatalog($0) }
    }

    func upsertProduct(_ p: CatalogProduct) async throws {
        guard let uid = await userId else { return }
        let row = DBProduct(id: p.id.uuidString, userId: uid, name: p.name, price: p.price,
                            category: p.category, description: p.description,
                            emoji: p.emoji, aliases: p.aliases, active: p.isActive)
        try await rest.upsert(table: "products", row: row)
    }

    func deleteProduct(id: UUID) async throws {
        try await rest.delete(table: "products", filters: ["id": id.uuidString])
    }

    // MARK: - Combos
    func fetchCombos() async throws -> [ProductCombo] {
        guard let uid = await userId else { return [] }
        let rows: [DBCombo] = try await rest.select(table: "combos",
                                                     filters: ["user_id": uid],
                                                     orderBy: "created_at")
        var combos: [ProductCombo] = []
        for row in rows {
            let items = try await fetchComboItems(comboId: row.id)
            combos.append(toCombo(row, items: items))
        }
        return combos
    }

    func fetchComboItems(comboId: String) async throws -> [ComboItem] {
        let rows: [DBComboItem] = try await rest.select(table: "combo_items",
                                                         filters: ["combo_id": comboId])
        return rows.map { toComboItem($0) }
    }

    func upsertCombo(_ c: ProductCombo) async throws {
        guard let uid = await userId else { return }
        let row = DBCombo(id: c.id.uuidString, userId: uid, name: c.name, description: "",
                          price: c.finalPrice, emoji: c.emoji,
                          aliases: c.aliases, active: c.isActive)
        try await rest.upsert(table: "combos", row: row)
        try await rest.delete(table: "combo_items", filters: ["combo_id": c.id.uuidString])
        if !c.items.isEmpty {
            let items = c.items.map {
                DBComboItem(id: $0.id.uuidString, comboId: c.id.uuidString,
                            productId: $0.productId.uuidString,
                            productName: $0.productName, quantity: $0.qty)
            }
            try await rest.insertMany(table: "combo_items", rows: items)
        }
    }

    func deleteCombo(id: UUID) async throws {
        try await rest.delete(table: "combos", filters: ["id": id.uuidString])
    }

    // MARK: - Sales
    func fetchSales(limit: Int = 200) async throws -> [SaleItem] {
        guard let uid = await userId else { return [] }
        let rows: [DBSale] = try await rest.select(table: "sales",
                                                    filters: ["user_id": uid],
                                                    orderBy: "created_at.desc",
                                                    limit: limit)
        var sales: [SaleItem] = []
        for row in rows {
            let items = try await fetchSaleItems(saleId: row.id)
            sales.append(toSale(row, items: items))
        }
        return sales
    }

    func insertSale(_ s: SaleItem) async throws {
        guard let uid = await userId else { return }
        let saleRow = DBSale(id: s.id.uuidString, userId: uid,
                             source: s.channel.rawValue, total: s.total)
        try await rest.insert(table: "sales", row: saleRow)
        if !s.products.isEmpty {
            let items = s.products.map { p in
                DBSaleItem(id: p.id.uuidString, saleId: s.id.uuidString,
                           productId: nil, comboId: nil,
                           itemName: p.name, quantity: p.qty,
                           unitPrice: p.price, subtotal: p.subtotal)
            }
            try await rest.insertMany(table: "sale_items", rows: items)
        }
    }

    func deleteSale(id: UUID) async throws {
        try await rest.delete(table: "sales", filters: ["id": id.uuidString])
    }

    private func fetchSaleItems(saleId: String) async throws -> [SaleProduct] {
        let rows: [DBSaleItem] = try await rest.select(table: "sale_items",
                                                        filters: ["sale_id": saleId])
        return rows.map { SaleProduct(id: UUID(uuidString: $0.id) ?? UUID(),
                                      name: $0.itemName, qty: $0.quantity, price: $0.unitPrice) }
    }

    // MARK: - Chat
    func fetchChatMessages(limit: Int = 50) async throws -> [ChatMessage] {
        guard let uid = await userId else { return [] }
        let rows: [DBChatMessage] = try await rest.select(table: "chat_messages",
                                                           filters: ["user_id": uid],
                                                           orderBy: "created_at",
                                                           limit: limit)
        return rows.map { ChatMessage(id: UUID(uuidString: $0.id) ?? UUID(),
                                      text: $0.content,
                                      isUser: $0.role == "user") }
    }

    func insertChatMessage(_ m: ChatMessage) async throws {
        guard let uid = await userId else { return }
        let row = DBChatMessage(id: m.id.uuidString, userId: uid,
                                role: m.isUser ? "user" : "assistant",
                                content: m.text)
        try await rest.insert(table: "chat_messages", row: row)
    }

    // MARK: - Business Profile
    func fetchProfile() async throws -> DBBusinessProfile? {
        guard let uid = await userId else { return nil }
        let rows: [DBBusinessProfile] = try await rest.select(table: "business_profiles",
                                                               filters: ["user_id": uid],
                                                               limit: 1)
        return rows.first
    }

    func upsertProfile(_ p: DBBusinessProfile) async throws {
        try await rest.upsert(table: "business_profiles", row: p)
    }

    // MARK: - Converters
    private func toCatalog(_ r: DBProduct) -> CatalogProduct {
        CatalogProduct(id: UUID(uuidString: r.id) ?? UUID(),
                       name: r.name, price: r.price, category: r.category,
                       emoji: r.emoji, description: r.description,
                       isActive: r.active, aliases: r.aliases)
    }

    private func toCombo(_ r: DBCombo, items: [ComboItem]) -> ProductCombo {
        ProductCombo(id: UUID(uuidString: r.id) ?? UUID(),
                     name: r.name, items: items, finalPrice: r.price,
                     emoji: r.emoji, isActive: r.active, aliases: r.aliases)
    }

    private func toComboItem(_ r: DBComboItem) -> ComboItem {
        ComboItem(id: UUID(uuidString: r.id) ?? UUID(),
                  productId: UUID(uuidString: r.productId ?? "") ?? UUID(),
                  productName: r.productName, qty: r.quantity, unitPrice: 0)
    }

    private func toSale(_ r: DBSale, items: [SaleProduct]) -> SaleItem {
        let channel: SaleChannel = SaleChannel(rawValue: r.source) ?? .manual
        return SaleItem(id: UUID(uuidString: r.id) ?? UUID(),
                        date: Date(), products: items,
                        total: r.total, channel: channel)
    }
}
