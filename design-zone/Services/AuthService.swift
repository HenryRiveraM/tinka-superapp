import Foundation
import SwiftUI

// MARK: - Sign Up Profile
struct SignUpProfile {
    var ownerName: String
    var businessName: String
    var businessType: String
    var city: String
    var phone: String
}

// MARK: - Auth Service
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isLoggedIn = false
    @Published var isLoading = true
    @Published var userId: String? = nil
    @Published var userEmail: String? = nil

    private let rest = SupabaseREST.shared
    private init() {}

    func initialize() async {
        let logged = await rest.isLoggedIn
        let uid = await rest.userId
        isLoggedIn = logged
        userId = uid
        isLoading = false
    }

    func signIn(email: String, password: String) async throws {
        let resp = try await rest.signIn(email: email, password: password)
        let restId = await rest.userId
        userId = resp.user?.id ?? restId
        userEmail = resp.user?.email ?? email
        isLoggedIn = true
    }

    func signUp(email: String, password: String, profile: SignUpProfile) async throws {
        let resp = try await rest.signUp(email: email, password: password)
        let restId = await rest.userId
        let uid = resp.user?.id ?? restId ?? ""
        userId = uid
        userEmail = resp.user?.email ?? email
        isLoggedIn = true
        if !uid.isEmpty {
            try await createProfile(userId: uid, profile: profile)
            try await seedDemoData(userId: uid)
        }
    }

    func signOut() async {
        await rest.signOut()
        userId = nil
        userEmail = nil
        isLoggedIn = false
    }

    func sendPasswordReset(email: String) async throws {
        try await rest.sendPasswordReset(email: email)
    }

    // MARK: - Profile creation
    private func createProfile(userId: String, profile: SignUpProfile) async throws {
        let row = DBBusinessProfile(
            id: UUID().uuidString,
            userId: userId,
            ownerName: profile.ownerName,
            businessName: profile.businessName,
            businessType: profile.businessType,
            city: profile.city,
            phone: profile.phone
        )
        try await SupabaseREST.shared.upsert(table: "business_profiles", row: row)
    }

    // MARK: - Demo seed data
    private func seedDemoData(userId: String) async throws {
        let demoProducts: [(name: String, price: Double, cat: String, emoji: String, aliases: [String])] = [
            ("Salteña",    5,  "Snack",  "🫓", ["salteña","salteñas","saltena","saltenas"]),
            ("Refresco",   4,  "Bebida", "🥤", ["refresco","refrescos","soda","fresco"]),
            ("Coca Cola",  12, "Bebida", "🥫", ["coca","coca cola","cocacola","gaseosa","cola"]),
            ("Silpancho",  25, "Comida", "🍽️", ["silpancho","silpanchos","silpacho"]),
            ("Kawi",       20, "Comida", "🍲", ["kawi","kawis","cawi","cawis","kavi"]),
            ("Trancapecho",18, "Comida", "🥩", ["trancapecho","trancapechos","tranca pecho"]),
            ("Almuerzo",   15, "Plato",  "🍱", ["almuerzo","almuerzos","plato del dia","menu","menú"]),
        ]
        var insertedIds: [(id: String, name: String)] = []
        for p in demoProducts {
            let id = UUID().uuidString
            let row = DBProduct(id: id, userId: userId, name: p.name, price: p.price,
                                category: p.cat, description: "", emoji: p.emoji,
                                aliases: p.aliases, active: true)
            try await SupabaseREST.shared.upsert(table: "products", row: row)
            insertedIds.append((id: id, name: p.name))
        }

        let comboId = UUID().uuidString
        let almuerzoId = insertedIds.first { $0.name == "Almuerzo" }?.id
        let refrescoId = insertedIds.first { $0.name == "Refresco" }?.id
        let comboRow = DBCombo(id: comboId, userId: userId, name: "Combo Almuerzo",
                               description: "Almuerzo completo", price: 18, emoji: "🎯",
                               aliases: ["combo almuerzo","combo","combos"], active: true)
        try await SupabaseREST.shared.upsert(table: "combos", row: comboRow)

        var comboItems: [DBComboItem] = []
        if let aid = almuerzoId {
            comboItems.append(DBComboItem(id: UUID().uuidString, comboId: comboId,
                                          productId: aid, productName: "Almuerzo", quantity: 1))
        }
        if let rid = refrescoId {
            comboItems.append(DBComboItem(id: UUID().uuidString, comboId: comboId,
                                          productId: rid, productName: "Refresco", quantity: 1))
        }
        if !comboItems.isEmpty {
            try await SupabaseREST.shared.insertMany(table: "combo_items", rows: comboItems)
        }
    }
}
