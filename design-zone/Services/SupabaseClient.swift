import Foundation
import Supabase

// MARK: - Supabase singleton
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://jhsnshxuxlnwkkbszcjx.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impoc25zaHh1eGxud2trYnN6Y2p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5ODY3OTcsImV4cCI6MjA5NDU2Mjc5N30.ZAnGMYebwuKUBPu_lW13h9cQH4J59Uc91uyQBHAFU_0"
)

// MARK: - DB Row types (Codable)

struct DBBusinessProfile: Codable {
    let id: UUID
    let userId: UUID
    var ownerName: String
    var businessName: String
    var businessType: String
    var city: String
    var phone: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, phone
        case userId = "user_id"
        case ownerName = "owner_name"
        case businessName = "business_name"
        case businessType = "business_type"
        case city
        case createdAt = "created_at"
    }
}

struct DBProduct: Codable {
    let id: UUID
    let userId: UUID
    var name: String
    var price: Double
    var category: String
    var description: String
    var emoji: String
    var aliases: [String]
    var active: Bool
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, price, category, description, emoji, aliases, active
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

struct DBCombo: Codable {
    let id: UUID
    let userId: UUID
    var name: String
    var description: String
    var price: Double
    var emoji: String
    var aliases: [String]
    var active: Bool
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, description, price, emoji, aliases, active
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

struct DBComboItem: Codable {
    let id: UUID
    let comboId: UUID
    var productId: UUID?
    var productName: String
    var quantity: Int

    enum CodingKeys: String, CodingKey {
        case id, quantity
        case comboId = "combo_id"
        case productId = "product_id"
        case productName = "product_name"
    }
}

struct DBSale: Codable {
    let id: UUID
    let userId: UUID
    var source: String
    var total: Double
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, source, total
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

struct DBSaleItem: Codable {
    let id: UUID
    let saleId: UUID
    var productId: UUID?
    var comboId: UUID?
    var itemName: String
    var quantity: Int
    var unitPrice: Double
    var subtotal: Double

    enum CodingKeys: String, CodingKey {
        case id, quantity, subtotal
        case saleId = "sale_id"
        case productId = "product_id"
        case comboId = "combo_id"
        case itemName = "item_name"
        case unitPrice = "unit_price"
    }
}

struct DBChatMessage: Codable {
    let id: UUID
    let userId: UUID
    var role: String
    var content: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, role, content
        case userId = "user_id"
        case createdAt = "created_at"
    }
}
