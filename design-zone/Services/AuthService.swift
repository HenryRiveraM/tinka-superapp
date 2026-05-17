import Foundation
import Supabase
import SwiftUI

// MARK: - Auth Service
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var session: Session? = nil
    @Published var isLoading = true

    var isLoggedIn: Bool { session != nil }
    var userId: UUID? { session?.user.id }
    var userEmail: String? { session?.user.email }

    private init() {}

    func initialize() async {
        do {
            session = try await supabase.auth.session
        } catch {
            session = nil
        }
        isLoading = false

        // Listen for auth state changes
        Task {
            for await (event, sess) in await supabase.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .signedIn: session = sess
                    case .signedOut: session = nil
                    case .tokenRefreshed: session = sess
                    default: break
                    }
                }
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        let result = try await supabase.auth.signIn(email: email, password: password)
        session = result.session
    }

    func signUp(email: String, password: String, profile: SignUpProfile) async throws {
        let result = try await supabase.auth.signUp(email: email, password: password)
        session = result.session
        if let uid = result.user?.id {
            try await createProfile(userId: uid, profile: profile)
            try await seedDemoData(userId: uid, ownerName: profile.ownerName)
        }
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        session = nil
    }

    func sendPasswordReset(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }

    // MARK: - Profile creation
    private func createProfile(userId: UUID, profile: SignUpProfile) async throws {
        let row = DBBusinessProfile(
            id: UUID(),
            userId: userId,
            ownerName: profile.ownerName,
            businessName: profile.businessName,
            businessType: profile.businessType,
            city: profile.city,
            phone: profile.phone,
            createdAt: nil
        )
        try await supabase.from("business_profiles").insert(row).execute()
    }

    // MARK: - Demo seed data
    private func seedDemoData(userId: UUID, ownerName: String) async throws {
        let demoProducts: [(name: String, price: Double, cat: String, emoji: String, aliases: [String])] = [
            ("Salteña",    5,  "Snack",   "🫓", ["salteña","salteñas","saltena","saltenas"]),
            ("Refresco",   4,  "Bebida",  "🥤", ["refresco","refrescos","soda","fresco"]),
            ("Coca Cola",  12, "Bebida",  "🥫", ["coca","coca cola","cocacola","gaseosa","cola"]),
            ("Silpancho",  25, "Comida",  "🍽️", ["silpancho","silpanchos","sil pancho","sil panchos","silpacho"]),
            ("Kawi",       20, "Comida",  "🍲", ["kawi","kawis","cawi","cawis","kajwi","kalwi","kavi","cavi"]),
            ("Trancapecho",18, "Comida",  "🥩", ["trancapecho","trancapechos","tranca pecho","tranca pechos"]),
            ("Almuerzo",   15, "Plato",   "🍱", ["almuerzo","almuerzos","plato del dia","menu","menú"]),
        ]

        var insertedProducts: [(id: UUID, name: String)] = []
        for p in demoProducts {
            let row = DBProduct(
                id: UUID(),
                userId: userId,
                name: p.name, price: p.price, category: p.cat,
                description: "", emoji: p.emoji, aliases: p.aliases,
                active: true, createdAt: nil
            )
            try await supabase.from("products").insert(row).execute()
            insertedProducts.append((id: row.id, name: p.name))
        }

        // Combo demo
        let comboId = UUID()
        let almuerzoProd = insertedProducts.first { $0.name == "Almuerzo" }
        let refrescoProd = insertedProducts.first { $0.name == "Refresco" }
        let comboRow = DBCombo(
            id: comboId, userId: userId,
            name: "Combo Almuerzo", description: "Almuerzo completo",
            price: 18, emoji: "🎯",
            aliases: ["combo almuerzo","combo","combos"],
            active: true, createdAt: nil
        )
        try await supabase.from("combos").insert(comboRow).execute()

        if let ap = almuerzoProd, let rp = refrescoProd {
            let items = [
                DBComboItem(id: UUID(), comboId: comboId, productId: ap.id, productName: "Almuerzo", quantity: 1),
                DBComboItem(id: UUID(), comboId: comboId, productId: rp.id, productName: "Refresco", quantity: 1)
            ]
            try await supabase.from("combo_items").insert(items).execute()
        }
    }
}

// MARK: - Sign Up Profile
struct SignUpProfile {
    var ownerName: String
    var businessName: String
    var businessType: String
    var city: String
    var phone: String
}
