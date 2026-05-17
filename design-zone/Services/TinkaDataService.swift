import Foundation
import Supabase

// MARK: - Tinka Data Service (Supabase CRUD)
@MainActor
class TinkaDataService {
    static let shared = TinkaDataService()
    private init() {}

    private var userId: UUID? { AuthService.shared.userId }

    // MARK: - Products
    func fetchProducts() async throws -> [CatalogProduct] {
        guard let uid = userId else { return [] }
        let rows: [DBProduct] = try await supabase
            .from("products")
            .select()
            .eq("user_id", value: uid)
            .order("created_at")
            .execute()
            .value
        return rows.map { toCatalog($0) }
    }

    func upsertProduct(_ p: CatalogProduct) async throws {
        guard let uid = userId else { return }
        let row = DBProduct(id: p.id, userId: uid, name: p.name, price: p.price,
                            category: p.category, description: p.description,
                            emoji: p.emoji, aliases: p.aliases, active: p.isActive, createdAt: nil)
        try await supabase.from("products").upsert(row).execute()
    }

    func deleteProduct(id: UUID) async throws {
        try await supabase.from("products").delete().eq("id", value: id).execute()
    }

    // MARK: - Combos
    func fetchCombos() async throws -> [ProductCombo] {
        guard let uid = userId else { return [] }
        let rows: [DBCombo] = try await supabase
            .from("combos")
            .select()
            .eq("user_id", value: uid)
            .order("created_at")
            .execute()
            .value
        var combos: [ProductCombo] = []
        for row in rows {
            let items = try await fetchComboItems(comboId: row.id)
            combos.append(toCombo(row, items: items))
        }
        return combos
    }

    func fetchComboItems(comboId: UUID) async throws -> [ComboItem] {
        let rows: [DBComboItem] = try await supabase
            .from("combo_items")
            .select()
            .eq("combo_id", value: comboId)
            .execute()
            .value
        return rows.map { toComboItem($0) }
    }

    func upsertCombo(_ c: ProductCombo) async throws {
        guard let uid = userId else { return }
        let row = DBCombo(id: c.id, userId: uid, name: c.name, description: "",
                          price: c.finalPrice, emoji: c.emoji,
                          aliases: c.aliases, active: c.isActive, createdAt: nil)
        try await supabase.from("combos").upsert(row).execute()
        // Delete old items, re-insert
        try await supabase.from("combo_items").delete().eq("combo_id", value: c.id).execute()
        if !c.items.isEmpty {
            let items = c.items.map {
                DBComboItem(id: $0.id, comboId: c.id, productId: $0.productId,
                            productName: $0.productName, quantity: $0.qty)
            }
            try await supabase.from("combo_items").insert(items).execute()
        }
    }

    func deleteCombo(id: UUID) async throws {
        try await supabase.from("combos").delete().eq("id", value: id).execute()
    }

    // MARK: - Sales
    func fetchSales(limit: Int = 200) async throws -> [SaleItem] {
        guard let uid = userId else { return [] }
        let rows: [DBSale] = try await supabase
            .from("sales")
            .select()
            .eq("user_id", value: uid)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        var sales: [SaleItem] = []
        for row in rows {
            let items = try await fetchSaleItems(saleId: row.id)
            sales.append(toSale(row, items: items))
        }
        return sales
    }

    func insertSale(_ s: SaleItem) async throws {
        guard let uid = userId else { return }
        let saleRow = DBSale(id: s.id, userId: uid,
                             source: s.channel.rawValue, total: s.total, createdAt: nil)
        try await supabase.from("sales").insert(saleRow).execute()
        if !s.products.isEmpty {
            let items = s.products.map { p in
                DBSaleItem(id: p.id, saleId: s.id, productId: nil, comboId: nil,
                           itemName: p.name, quantity: p.qty,
                           unitPrice: p.price, subtotal: p.subtotal)
            }
            try await supabase.from("sale_items").insert(items).execute()
        }
    }

    func deleteSale(id: UUID) async throws {
        try await supabase.from("sales").delete().eq("id", value: id).execute()
    }

    private func fetchSaleItems(saleId: UUID) async throws -> [SaleProduct] {
        let rows: [DBSaleItem] = try await supabase
            .from("sale_items")
            .select()
            .eq("sale_id", value: saleId)
            .execute()
            .value
        return rows.map { SaleProduct(id: $0.id, name: $0.itemName, qty: $0.quantity, price: $0.unitPrice) }
    }

    // MARK: - Chat
    func fetchChatMessages(limit: Int = 50) async throws -> [ChatMessage] {
        guard let uid = userId else { return [] }
        let rows: [DBChatMessage] = try await supabase
            .from("chat_messages")
            .select()
            .eq("user_id", value: uid)
            .order("created_at", ascending: true)
            .limit(limit)
            .execute()
            .value
        return rows.map { ChatMessage(id: $0.id, text: $0.content, isUser: $0.role == "user",
                                      timestamp: $0.createdAt ?? Date()) }
    }

    func insertChatMessage(_ m: ChatMessage) async throws {
        guard let uid = userId else { return }
        let row = DBChatMessage(id: m.id, userId: uid,
                                role: m.isUser ? "user" : "assistant",
                                content: m.text, createdAt: nil)
        try await supabase.from("chat_messages").insert(row).execute()
    }

    // MARK: - Business Profile
    func fetchProfile() async throws -> DBBusinessProfile? {
        guard let uid = userId else { return nil }
        let rows: [DBBusinessProfile] = try await supabase
            .from("business_profiles")
            .select()
            .eq("user_id", value: uid)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func upsertProfile(_ p: DBBusinessProfile) async throws {
        try await supabase.from("business_profiles").upsert(p).execute()
    }

    // MARK: - Converters
    private func toCatalog(_ r: DBProduct) -> CatalogProduct {
        CatalogProduct(id: r.id, name: r.name, price: r.price, category: r.category,
                       emoji: r.emoji, description: r.description, isActive: r.active, aliases: r.aliases)
    }

    private func toCombo(_ r: DBCombo, items: [ComboItem]) -> ProductCombo {
        ProductCombo(id: r.id, name: r.name, items: items, finalPrice: r.price,
                     emoji: r.emoji, isActive: r.active, aliases: r.aliases)
    }

    private func toComboItem(_ r: DBComboItem) -> ComboItem {
        ComboItem(id: r.id, productId: r.productId ?? UUID(),
                  productName: r.productName, qty: r.quantity, unitPrice: 0)
    }

    private func toSale(_ r: DBSale, items: [SaleProduct]) -> SaleItem {
        let channel: SaleChannel = SaleChannel(rawValue: r.source) ?? .manual
        return SaleItem(id: r.id, date: r.createdAt ?? Date(), products: items,
                        total: r.total, channel: channel)
    }
}
