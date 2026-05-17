import Foundation

// MARK: - Supabase REST Client (no external SDK)

let supabaseURL = "https://jhsnshxuxlnwkkbszcjx.supabase.co"
let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impoc25zaHh1eGxud2trYnN6Y2p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5ODY3OTcsImV4cCI6MjA5NDU2Mjc5N30.ZAnGMYebwuKUBPu_lW13h9cQH4J59Uc91uyQBHAFU_0"

// MARK: - Session model
struct TinkaSession: Codable {
    let accessToken: String
    let refreshToken: String
    let userId: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case userId = "user_id"
    }
}

// MARK: - Auth response models
struct AuthResponse: Codable {
    let accessToken: String?
    let refreshToken: String?
    let user: AuthUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct AuthUser: Codable {
    let id: String
    let email: String?
    let identities: [AuthIdentity]?
}

struct AuthIdentity: Codable {
    let id: String?
}

// MARK: - REST errors
enum SupabaseError: LocalizedError {
    case invalidURL, noSession, httpError(Int, String), decodingError(Error)

    var statusCode: Int? {
        if case .httpError(let code, _) = self { return code }
        return nil
    }

    var rawMessage: String {
        switch self {
        case .httpError(_, let msg): return msg
        case .invalidURL: return "URL inválida"
        case .noSession: return "Sesión no encontrada"
        case .decodingError(let e): return e.localizedDescription
        }
    }

    var apiErrorCode: String? {
        guard case .httpError(_, let msg) = self,
              let data = msg.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json["error_code"] as? String
            ?? json["code"] as? String
            ?? json["error"] as? String
    }

    var apiMessage: String? {
        guard case .httpError(_, let msg) = self,
              let data = msg.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json["msg"] as? String
            ?? json["message"] as? String
            ?? json["error_description"] as? String
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL inválida"
        case .noSession: return "Sesión no encontrada"
        case .httpError(let code, let msg):
            let friendlyMessage = apiMessage ?? msg
            return "Error \(code): \(friendlyMessage)"
        case .decodingError(let e): return "Error de datos: \(e.localizedDescription)"
        }
    }
}

// MARK: - DB Row types (Codable)

struct DBBusinessProfile: Codable {
    var id: String
    var userId: String
    var ownerName: String
    var businessName: String
    var businessType: String
    var city: String
    var phone: String

    enum CodingKeys: String, CodingKey {
        case id, phone, city
        case userId = "user_id"
        case ownerName = "owner_name"
        case businessName = "business_name"
        case businessType = "business_type"
    }
}

struct DBProduct: Codable {
    var id: String
    var userId: String
    var name: String
    var price: Double
    var category: String
    var description: String
    var emoji: String
    var aliases: [String]
    var active: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, price, category, description, emoji, aliases, active
        case userId = "user_id"
    }
}

struct DBCombo: Codable {
    var id: String
    var userId: String
    var name: String
    var description: String
    var price: Double
    var emoji: String
    var aliases: [String]
    var active: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, description, price, emoji, aliases, active
        case userId = "user_id"
    }
}

struct DBComboItem: Codable {
    var id: String
    var userId: String
    var comboId: String
    var productId: String?
    var productName: String
    var quantity: Int

    enum CodingKeys: String, CodingKey {
        case id, quantity
        case userId = "user_id"
        case comboId = "combo_id"
        case productId = "product_id"
        case productName = "product_name"
    }
}

struct DBSale: Codable {
    var id: String
    var userId: String
    var source: String
    var total: Double

    enum CodingKeys: String, CodingKey {
        case id, source, total
        case userId = "user_id"
    }
}

struct DBSaleItem: Codable {
    var id: String
    var userId: String
    var saleId: String
    var productId: String?
    var comboId: String?
    var itemName: String
    var quantity: Int
    var unitPrice: Double
    var subtotal: Double

    enum CodingKeys: String, CodingKey {
        case id, quantity, subtotal
        case userId = "user_id"
        case saleId = "sale_id"
        case productId = "product_id"
        case comboId = "combo_id"
        case itemName = "item_name"
        case unitPrice = "unit_price"
    }
}

struct DBChatMessage: Codable {
    var id: String
    var userId: String
    var role: String
    var content: String

    enum CodingKeys: String, CodingKey {
        case id, role, content
        case userId = "user_id"
    }
}

// MARK: - Supabase REST Client

actor SupabaseREST {
    static let shared = SupabaseREST()

    private let baseURL = supabaseURL
    private let anonKey = supabaseAnonKey
    private let sessionKey = "tinka_session_v1"
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private(set) var session: TinkaSession? {
        didSet { persistSession() }
    }

    private init() {
        decoder = JSONDecoder()
        encoder = JSONEncoder()
        if let data = UserDefaults.standard.data(forKey: sessionKey),
           let sess = try? JSONDecoder().decode(TinkaSession.self, from: data) {
            session = sess
        }
    }

    var userId: String? {
        guard let token = session?.accessToken else { return nil }
        return jwtUserId(token)
    }
    var accessToken: String? { session?.accessToken }
    var isLoggedIn: Bool { session != nil }

    // MARK: - Auth

    func signIn(email: String, password: String) async throws -> AuthResponse {
        let body = ["email": email, "password": password]
        let data = try await post(path: "/auth/v1/token?grant_type=password", body: body, auth: false)
        let resp = try decodeAuth(data)
        guard setSessionIfPresent(from: resp) else { throw SupabaseError.noSession }
        return resp
    }

    func signUp(email: String, password: String) async throws -> AuthResponse {
        let body = ["email": email, "password": password]
        let data = try await post(path: "/auth/v1/signup", body: body, auth: false)
        let resp = try decodeAuth(data)
        _ = setSessionIfPresent(from: resp)
        return resp
    }

    func signOut() {
        session = nil
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    func sendPasswordReset(email: String) async throws {
        let body = ["email": email]
        _ = try await post(path: "/auth/v1/recover", body: body, auth: false)
    }

    // MARK: - PostgREST helpers

    func select<T: Decodable>(table: String, filters: [String: String] = [:],
                               orderBy: String? = nil, limit: Int? = nil) async throws -> [T] {
        guard let token = accessToken else { throw SupabaseError.noSession }
        var urlStr = "\(baseURL)/rest/v1/\(table)?"
        for (key, val) in filters { urlStr += "\(key)=eq.\(val)&" }
        if let o = orderBy { urlStr += "order=\(o)&" }
        if let l = limit { urlStr += "limit=\(l)&" }
        guard let url = URL(string: urlStr) else { throw SupabaseError.invalidURL }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, resp) = try await URLSession.shared.data(for: req)
        try checkHTTP(resp, data)
        do { return try decoder.decode([T].self, from: data) }
        catch { throw SupabaseError.decodingError(error) }
    }

    func insert<T: Encodable>(table: String, row: T) async throws {
        guard let token = accessToken else { throw SupabaseError.noSession }
        let data = try await postREST(table: table, body: encoder.encode(row), token: token, method: "POST")
        _ = data
    }

    func insertMany<T: Encodable>(table: String, rows: [T]) async throws {
        guard !rows.isEmpty else { return }
        guard let token = accessToken else { throw SupabaseError.noSession }
        let data = try await postREST(table: table, body: encoder.encode(rows), token: token, method: "POST")
        _ = data
    }

    func upsert<T: Encodable>(table: String, row: T) async throws {
        guard let token = accessToken else { throw SupabaseError.noSession }
        let data = try await postREST(table: table, body: encoder.encode(row), token: token, method: "POST", prefer: "resolution=merge-duplicates,return=minimal")
        _ = data
    }

    func delete(table: String, filters: [String: String]) async throws {
        guard let token = accessToken else { throw SupabaseError.noSession }
        var urlStr = "\(baseURL)/rest/v1/\(table)?"
        for (key, val) in filters { urlStr += "\(key)=eq.\(val)&" }
        guard let url = URL(string: urlStr) else { throw SupabaseError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, resp) = try await URLSession.shared.data(for: req)
        try checkHTTP(resp, data)
    }

    // MARK: - Private helpers

    private func post(path: String, body: [String: String], auth: Bool) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw SupabaseError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if auth, let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try encoder.encode(body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        try checkHTTP(resp, data)
        return data
    }

    private func postREST(table: String, body: Data, token: String,
                          method: String, prefer: String = "return=minimal") async throws -> Data {
        guard let url = URL(string: "\(baseURL)/rest/v1/\(table)") else { throw SupabaseError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.httpBody = body
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(prefer, forHTTPHeaderField: "Prefer")
        let (data, resp) = try await URLSession.shared.data(for: req)
        try checkHTTP(resp, data)
        return data
    }

    private func checkHTTP(_ response: URLResponse, _ data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard http.statusCode >= 200 && http.statusCode < 300 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SupabaseError.httpError(http.statusCode, msg)
        }
    }

    private func decodeAuth(_ data: Data) throws -> AuthResponse {
        do { return try decoder.decode(AuthResponse.self, from: data) }
        catch { throw SupabaseError.decodingError(error) }
    }

    private func setSessionIfPresent(from resp: AuthResponse) -> Bool {
        guard let at = resp.accessToken, let rt = resp.refreshToken,
              let uid = resp.user?.id ?? jwtUserId(resp.accessToken ?? "") else {
            return false
        }
        session = TinkaSession(accessToken: at, refreshToken: rt, userId: uid)
        return true
    }

    private func jwtUserId(_ token: String) -> String? {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else { return nil }
        var base64 = parts[1]
        let rem = base64.count % 4
        if rem > 0 { base64 += String(repeating: "=", count: 4 - rem) }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sub = json["sub"] as? String else { return nil }
        return sub
    }

    // MARK: - Session persistence (UserDefaults, no secret data)
    private func persistSession() {
        if let sess = session, let data = try? JSONEncoder().encode(sess) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        } else {
            UserDefaults.standard.removeObject(forKey: sessionKey)
        }
    }
}
