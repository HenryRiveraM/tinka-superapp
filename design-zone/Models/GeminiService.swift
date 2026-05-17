import Foundation

// MARK: - Tinka AI Service (Secure Supabase Proxy → Gemini 2.0 Flash)

actor GeminiService {
    static let shared = GeminiService()

    private let endpointURL = URL(string: "https://jhsnshxuxlnwkkbszcjx.supabase.co/functions/v1/tinka-ai")!
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impoc25zaHh1eGxud2trYnN6Y2p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5ODY3OTcsImV4cCI6MjA5NDU2Mjc5N30.ZAnGMYebwuKUBPu_lW13h9cQH4J59Uc91uyQBHAFU_0"

    /// Calls the edge function with one automatic retry on failure.
    func chat(userMessage: String, businessContext: String) async throws -> String {
        do {
            return try await callEdge(userMessage: userMessage, businessContext: businessContext)
        } catch let firstError {
            NSLog("[Tinka AI] First attempt failed: \(firstError.localizedDescription) — retrying…")
            do {
                try await Task.sleep(nanoseconds: 1_500_000_000)
                return try await callEdge(userMessage: userMessage, businessContext: businessContext)
            } catch let secondError {
                NSLog("[Tinka AI] Retry also failed: \(secondError.localizedDescription)")
                throw secondError
            }
        }
    }

    private func callEdge(userMessage: String, businessContext: String) async throws -> String {
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let body: [String: String] = ["message": userMessage, "context": businessContext]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw TinkaAIError.network }

        guard http.statusCode == 200 else {
            let detail = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String ?? "HTTP \(http.statusCode)"
            throw TinkaAIError.server(detail)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let reply = json["reply"] as? String, !reply.isEmpty else {
            throw TinkaAIError.parse
        }
        return reply
    }
}

enum TinkaAIError: LocalizedError {
    case network, parse, server(String)
    var errorDescription: String? {
        switch self {
        case .network:       return "Sin conexión. Verifica tu red."
        case .parse:         return "Error procesando respuesta."
        case .server(let m): return m
        }
    }
}

// MARK: - Smart Local Fallback (when network unavailable)

enum TinkaLocalAI {
    static func reply(for q: String, state: AppState) -> String {
        let question = q.lowercased()
        let today = state.todaySales
        let todayCount = state.todaySaleCount
        let week = state.weekSales
        let weekCount = state.weekSaleCount
        let top = state.topProduct
        let status = state.financialStatus
        let ticket = Int(state.averageTicket)
        let utility = Int(state.utilityEstimate)
        let score = state.tinkaScore
        let activeProds = state.catalogProducts.filter { $0.isActive }
        let activeCombos = state.combos.filter { $0.isActive }

        if question.contains("hoy") || question.contains("resumen") || question.contains("día") {
            if today == 0 { return "📅 Aún no hay ventas hoy, Doña María. ¡Registra tu primera venta con el micrófono 🎤!" }
            return "📅 Hoy llevas **Bs. \(Int(today))** en \(todayCount) venta(s). Utilidad estimada: Bs. \(Int(today * 0.35)). Estado: **\(status)**. \(today >= 300 ? "¡Excelente jornada! 🌟" : "Sigue adelante 💪")"
        }
        if question.contains("semana") || question.contains("negocio") || question.contains("cómo va") || question.contains("como va") {
            return "📊 Esta semana: **Bs. \(Int(week))** en \(weekCount) ventas. Utilidad: Bs. \(utility). Producto estrella: **\(top)**. Score: **\(score)/100** — Estado: **\(status)**."
        }
        if question.contains("producto") || question.contains("estrella") || question.contains("vendo más") || question.contains("vendo mas") {
            return "⭐ Tu producto más vendido es **\(top)**. Ticket promedio: Bs. \(ticket). Tienes \(activeProds.count) productos activos en tu catálogo."
        }
        if question.contains("combo") || question.contains("promoción") || question.contains("promocion") {
            if activeCombos.isEmpty {
                let sugs = activeProds.prefix(2).map { $0.name }.joined(separator: " + ")
                return "💡 Aún no tienes combos. Te recomiendo crear uno combinando: **\(sugs.isEmpty ? "tus productos más vendidos" : sugs)**. Ve al Catálogo → Combos para crearlo."
            }
            let comboList = activeCombos.map { "\($0.emoji) \($0.name) (Bs. \(Int($0.finalPrice)))" }.joined(separator: ", ")
            return "🎁 Tus combos activos: \(comboList). ¡Promociónales para subir tu ticket promedio!"
        }
        if question.contains("score") || question.contains("puntaje") || question.contains("mejorar") {
            let tip = score >= 80 ? "¡Excelente nivel! 🏆 Mantén la constancia." : score >= 60 ? "Registra ventas todos los días para subir más 📈" : "Consejo: registra CADA venta, aunque sea pequeña. Suma al score."
            return "📈 Tu Tinka Score es **\(score)/100**. \(tip)"
        }
        if question.contains("utilidad") || question.contains("ganancia") || question.contains("ingreso") {
            return "💵 Utilidad estimada esta semana: **Bs. \(utility)** (35% de Bs. \(Int(week))). Hoy: Bs. \(Int(today * 0.35)). \(utility > 300 ? "¡Muy buen margen! 🌟" : "Sigue vendiendo para mejorar 💪")"
        }
        if question.contains("catálogo") || question.contains("catalogo") || question.contains("productos") {
            let names = activeProds.map { "\($0.emoji) \($0.name)" }.joined(separator: ", ")
            return "🛍️ Tienes **\(activeProds.count)** productos activos: \(names.isEmpty ? "ninguno aún" : names). Ve al Catálogo para agregar más."
        }
        return "🤖 Hola Doña María — Hoy: **Bs. \(Int(today))**, semana: **Bs. \(Int(week))**, score: **\(score)/100**, estrella: **\(top)**. ¿En qué más te ayudo?"
    }
}
