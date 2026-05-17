import Foundation
import SwiftUI

// MARK: - Sign Up Profile
struct SignUpProfile: Codable {
    var ownerName: String
    var businessName: String
    var businessType: String
    var city: String
    var phone: String
}

private struct PendingSignUpProfile: Codable {
    let email: String
    let profile: SignUpProfile
}

enum SignUpResult {
    case signedIn
    case needsEmailConfirmation
}

enum AuthFlowError: LocalizedError {
    case emailRateLimited(seconds: Int)
    case accountAlreadyExists
    case generic(String)

    var errorDescription: String? {
        switch self {
        case .emailRateLimited:
            return "Ya solicitaste un registro hace poco. Espera unos segundos e intenta nuevamente."
        case .accountAlreadyExists:
            return "Esta cuenta ya existe. Intenta iniciar sesión."
        case .generic(let message):
            return message
        }
    }
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
    private let pendingSignUpKey = "tinka_pending_signup_profile_v1"
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
        do {
            try await completePendingSignUpIfNeeded(email: email)
            try await ensureProfileForSignedInUser(email: email)
        } catch {
            NSLog("[Auth] Login post-setup failed: \(error.localizedDescription)")
        }
    }

    func signUp(email: String, password: String, profile: SignUpProfile) async throws -> SignUpResult {
        let resp: AuthResponse
        do {
            resp = try await rest.signUp(email: email, password: password)
        } catch {
            throw mapSignUpError(error)
        }

        let restId = await rest.userId
        userEmail = resp.user?.email ?? email

        if resp.user?.identities?.isEmpty == true {
            throw AuthFlowError.accountAlreadyExists
        }

        guard let uid = restId, resp.accessToken != nil else {
            isLoggedIn = false
            savePendingSignUp(email: email, profile: profile)
            return .needsEmailConfirmation
        }

        userId = uid
        isLoggedIn = true
        try await createOrUpdateProfile(userId: uid, profile: profile)
        clearPendingSignUp()
        return .signedIn
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

    func seedStarterCatalogForCurrentUser() async throws {
        guard let uid = userId else { throw SupabaseError.noSession }
        try await seedStarterDataIfNeeded(userId: uid)
    }

    // MARK: - Profile creation
    private func createOrUpdateProfile(userId: String, profile: SignUpProfile) async throws {
        let existing: [DBBusinessProfile] = try await rest.select(table: "business_profiles",
                                                                  filters: ["user_id": userId],
                                                                  limit: 1)
        let row = DBBusinessProfile(
            id: existing.first?.id ?? UUID().uuidString,
            userId: userId,
            ownerName: profile.ownerName,
            businessName: profile.businessName,
            businessType: profile.businessType,
            city: profile.city,
            phone: profile.phone
        )
        try await rest.upsert(table: "business_profiles", row: row)
    }

    private func ensureProfileForSignedInUser(email: String) async throws {
        guard let uid = userId else { return }
        let existing: [DBBusinessProfile] = try await rest.select(table: "business_profiles",
                                                                  filters: ["user_id": uid],
                                                                  limit: 1)
        if existing.isEmpty {
            let emailName = email.split(separator: "@").first.map(String.init) ?? "Usuario"
            let cleanName = emailName
                .replacingOccurrences(of: ".", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
            let fallbackProfile = SignUpProfile(
                ownerName: cleanName.isEmpty ? "la vendedora" : cleanName,
                businessName: "Mi negocio",
                businessType: "Comida",
                city: "Cochabamba",
                phone: ""
            )
            try await createOrUpdateProfile(userId: uid, profile: fallbackProfile)
        }
    }

    // MARK: - Starter catalog
    private func seedStarterDataIfNeeded(userId: String) async throws {
        let existingProducts: [DBProduct] = try await rest.select(table: "products",
                                                                  filters: ["user_id": userId])
        let existingNames = Set(existingProducts.map { VoiceNormalizer.normalize($0.name) })

        let starterProducts: [(name: String, price: Double, cat: String, emoji: String, aliases: [String])] = [
            ("Salteña",    5,  "Snack",  "🫓", ["salteña","salteñas","saltena","saltenas"]),
            ("Refresco",   4,  "Bebida", "🥤", ["refresco","refrescos","soda","fresco"]),
            ("Coca Cola",  12, "Bebida", "🥫", ["coca","coca cola","cocacola","gaseosa","cola"]),
            ("Silpancho",  25, "Comida", "🍽️", ["silpancho","silpanchos","silpacho"]),
            ("Kawi",       20, "Comida", "🍲", ["kawi","kawis","cawi","cawis","kavi"]),
            ("Trancapecho",18, "Comida", "🥩", ["trancapecho","trancapechos","tranca pecho"]),
            ("Almuerzo",   15, "Plato",  "🍱", ["almuerzo","almuerzos","plato del dia","menu","menú"]),
        ]
        var productIdsByName: [String: String] = Dictionary(uniqueKeysWithValues: existingProducts.map { ($0.name, $0.id) })
        for p in starterProducts {
            guard !existingNames.contains(VoiceNormalizer.normalize(p.name)) else { continue }
            let id = UUID().uuidString
            let row = DBProduct(id: id, userId: userId, name: p.name, price: p.price,
                                category: p.cat, description: "", emoji: p.emoji,
                                aliases: p.aliases, active: true)
            try await rest.upsert(table: "products", row: row)
            productIdsByName[p.name] = id
        }

        let existingCombos: [DBCombo] = try await rest.select(table: "combos",
                                                              filters: ["user_id": userId])
        let comboExists = existingCombos.contains {
            VoiceNormalizer.normalize($0.name) == VoiceNormalizer.normalize("Combo Almuerzo")
        }
        guard !comboExists else { return }

        let comboId = UUID().uuidString
        let almuerzoId = productIdsByName["Almuerzo"]
        let refrescoId = productIdsByName["Refresco"]
        let comboRow = DBCombo(id: comboId, userId: userId, name: "Combo Almuerzo",
                               description: "Almuerzo completo", price: 18, emoji: "🎯",
                               aliases: ["combo almuerzo","combo","combos"], active: true)
        try await rest.upsert(table: "combos", row: comboRow)

        var comboItems: [DBComboItem] = []
        if let aid = almuerzoId {
            comboItems.append(DBComboItem(id: UUID().uuidString, userId: userId, comboId: comboId,
                                          productId: aid, productName: "Almuerzo", quantity: 1))
        }
        if let rid = refrescoId {
            comboItems.append(DBComboItem(id: UUID().uuidString, userId: userId, comboId: comboId,
                                          productId: rid, productName: "Refresco", quantity: 1))
        }
        if !comboItems.isEmpty {
            try await rest.insertMany(table: "combo_items", rows: comboItems)
        }
    }

    private func mapSignUpError(_ error: Error) -> Error {
        guard let supabaseError = error as? SupabaseError else { return error }
        let code = supabaseError.apiErrorCode?.lowercased() ?? ""
        let message = (supabaseError.apiMessage ?? supabaseError.rawMessage).lowercased()

        if supabaseError.statusCode == 429 || code == "over_email_send_rate_limit" {
            return AuthFlowError.emailRateLimited(seconds: retrySeconds(from: message) ?? 55)
        }

        if code.contains("user_already")
            || code.contains("email_exists")
            || message.contains("already registered")
            || message.contains("already exists")
            || message.contains("user already") {
            return AuthFlowError.accountAlreadyExists
        }

        return AuthFlowError.generic("No se pudo crear la cuenta. Intenta nuevamente.")
    }

    private func retrySeconds(from message: String) -> Int? {
        let pattern = #"after\s+(\d+)\s+seconds"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)),
              let range = Range(match.range(at: 1), in: message) else {
            return nil
        }
        return Int(message[range])
    }

    private func completePendingSignUpIfNeeded(email: String) async throws {
        guard let pending = pendingSignUp(),
              pending.email == email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
              let uid = userId else {
            return
        }
        try await createOrUpdateProfile(userId: uid, profile: pending.profile)
        clearPendingSignUp()
    }

    private func savePendingSignUp(email: String, profile: SignUpProfile) {
        let pending = PendingSignUpProfile(
            email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
            profile: profile
        )
        if let data = try? JSONEncoder().encode(pending) {
            UserDefaults.standard.set(data, forKey: pendingSignUpKey)
        }
    }

    private func pendingSignUp() -> PendingSignUpProfile? {
        guard let data = UserDefaults.standard.data(forKey: pendingSignUpKey) else { return nil }
        return try? JSONDecoder().decode(PendingSignUpProfile.self, from: data)
    }

    private func clearPendingSignUp() {
        UserDefaults.standard.removeObject(forKey: pendingSignUpKey)
    }
}
