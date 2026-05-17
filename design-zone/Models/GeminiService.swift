import Foundation

// MARK: - Tinka AI Service
// Architecture: TinkaLocalAI (always works) + optional Gemini bonus in background

actor GeminiService {
    static let shared = GeminiService()

    private let endpointURL = URL(string: "https://jhsnshxuxlnwkkbszcjx.supabase.co/functions/v1/tinka-ai")!
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impoc25zaHh1eGxud2trYnN6Y2p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5ODY3OTcsImV4cCI6MjA5NDU2Mjc5N30.ZAnGMYebwuKUBPu_lW13h9cQH4J59Uc91uyQBHAFU_0"

    /// Always returns a response. Uses Gemini if available, local AI otherwise.
    func chat(userMessage: String, businessContext: String, state: AppState) async -> String {
        // Always compute local answer immediately
        let localAnswer = TinkaLocalAI.reply(for: userMessage, state: state)

        // Try Gemini silently in background with short timeout
        do {
            let remote = try await callEdgeWithTimeout(
                userMessage: userMessage,
                businessContext: businessContext,
                timeout: 8.0
            )
            if !remote.isEmpty { return remote }
        } catch {
            NSLog("[Tinka AI] Gemini unavailable (\(error.localizedDescription)), using local.")
        }
        return localAnswer
    }

    private func callEdgeWithTimeout(userMessage: String, businessContext: String, timeout: TimeInterval) async throws -> String {
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = timeout

        let body: [String: String] = ["message": userMessage, "context": businessContext]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TinkaAIError.server("non-200")
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let reply = json["reply"] as? String, !reply.isEmpty else {
            throw TinkaAIError.parse
        }
        return reply
    }
}

enum TinkaAIError: Error {
    case network, parse, server(String)
}

// MARK: - Tinka Local AI (always-on, data-driven)

enum TinkaLocalAI {

    // MARK: Main dispatcher
    static func reply(for question: String, state: AppState) -> String {
        let q = question.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        // Route by intent
        if matches(q, ["hoy", "dia", "resumen del dia", "como amanecio"]) {
            return dailySummary(state)
        }
        if matches(q, ["semana", "esta semana", "semanal"]) {
            return weeklySummary(state)
        }
        if matches(q, ["negocio", "como voy", "como va", "en general", "situacion"]) {
            return businessOverview(state)
        }
        if matches(q, ["producto", "estrella", "mas vendo", "mas vendido", "top", "popular"]) {
            return topProductAnalysis(state)
        }
        if matches(q, ["combo", "promocion", "paquete", "oferta", "bundle"]) {
            return comboRecommendation(state)
        }
        if matches(q, ["precio", "cuanto cobrar", "aumentar precio", "bajar precio"]) {
            return pricingAdvice(state)
        }
        if matches(q, ["mejorar", "consejo", "tip", "recomendacion", "que hago", "que puedo"]) {
            return improvementTips(state)
        }
        if matches(q, ["score", "puntaje", "tinka score", "calificacion"]) {
            return scoreAnalysis(state)
        }
        if matches(q, ["utilidad", "ganancia", "margen", "ingreso", "dinero"]) {
            return profitAnalysis(state)
        }
        if matches(q, ["cliente", "clientes", "ventas del mes", "mes"]) {
            return monthlySummary(state)
        }
        if matches(q, ["catalogo", "productos", "cuantos productos", "inventario"]) {
            return catalogSummary(state)
        }
        if matches(q, ["gracias", "perfecto", "excelente", "genial", "bien"]) {
            return "¡De nada, Doña María! 😊 Aquí estaré cuando me necesites. ¡Sigamos creciendo juntas! 🚀"
        }
        if matches(q, ["hola", "buenas", "buenos dias", "buenas tardes"]) {
            return greeting(state)
        }

        // Default: business overview
        return businessOverview(state)
    }

    // MARK: - Intents

    private static func greeting(_ s: AppState) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let saludo = hour < 12 ? "¡Buenos días" : hour < 19 ? "¡Buenas tardes" : "¡Buenas noches"
        let today = s.todaySales
        if today == 0 {
            return "\(saludo), Doña María! 👋 Hoy aún no hay ventas registradas. ¿Empezamos? Usa el micrófono 🎤 o registra desde Ventas."
        }
        return "\(saludo), Doña María! Llevas **Bs. \(Int(today))** hoy. Score: **\(s.tinkaScore)/100**. ¿En qué te ayudo? 🌟"
    }

    private static func dailySummary(_ s: AppState) -> String {
        let today = s.todaySales
        let count = s.todaySaleCount
        let util = Int(today * 0.35)
        if today == 0 {
            return "📅 Hoy todavía no hay ventas registradas, Doña María.\n¡Comienza con el micrófono 🎤 o desde la pantalla de Ventas!"
        }
        let extra = today >= 300 ? "¡Excelente jornada! 🏆" : today >= 150 ? "¡Vas muy bien! 💪" : "Sigue adelante, cada venta cuenta 🌱"
        return "📅 **Resumen de hoy:**\n• Ventas: Bs. \(Int(today)) en \(count) transacción(es)\n• Utilidad estimada: Bs. \(util)\n• Estado: \(s.financialStatus)\n\n\(extra)"
    }

    private static func weeklySummary(_ s: AppState) -> String {
        let week = s.weekSales
        let count = s.weekSaleCount
        let util = Int(s.utilityEstimate)
        let ticket = Int(s.averageTicket)
        let top = s.topProduct
        return "📊 **Esta semana:**\n• Ventas: Bs. \(Int(week)) en \(count) transacciones\n• Utilidad: ~Bs. \(util)\n• Ticket promedio: Bs. \(ticket)\n• Producto estrella: **\(top)** ⭐\n\nScore actual: **\(s.tinkaScore)/100**"
    }

    private static func monthlySummary(_ s: AppState) -> String {
        let month = s.monthSales
        let util = Int(month * 0.35)
        let top = s.topProduct
        return "📆 **Este mes:**\n• Ventas totales: Bs. \(Int(month))\n• Utilidad estimada: Bs. \(util)\n• Producto líder: **\(top)** ⭐\n\n\(month >= 3000 ? "¡Mes excelente! 🏆" : month >= 1500 ? "Buen mes, puedes mejorar 💪" : "Hay espacio para crecer 📈")"
    }

    private static func businessOverview(_ s: AppState) -> String {
        let week = s.weekSales
        let today = s.todaySales
        let score = s.tinkaScore
        let top = s.topProduct
        let status = s.financialStatus
        let util = Int(s.utilityEstimate)
        var lines = [
            "📈 **Tu negocio esta semana:**",
            "• Ingresos: Bs. \(Int(week)) | Hoy: Bs. \(Int(today))",
            "• Utilidad estimada: Bs. \(util)",
            "• Producto estrella: **\(top)**",
            "• Estado: **\(status)** | Score: **\(score)/100**"
        ]
        if score < 60 { lines.append("\n💡 Consejo: Registra ventas cada día para subir tu score.") }
        else if score >= 80 { lines.append("\n🏆 ¡Excelente nivel! Mantén la constancia.") }
        return lines.joined(separator: "\n")
    }

    private static func topProductAnalysis(_ s: AppState) -> String {
        let tops = s.topProductsSummary
        if tops.isEmpty {
            let names = s.catalogProducts.filter { $0.isActive }.map { "\($0.emoji) \($0.name)" }.joined(separator: ", ")
            return "📦 Aún no hay suficientes ventas para detectar el producto estrella.\nTienes en catálogo: \(names.isEmpty ? "sin productos" : names)\n\n¡Registra ventas para ver tus estadísticas! 🎯"
        }
        var msg = "⭐ **Tus productos más vendidos:**\n"
        for (i, p) in tops.prefix(5).enumerated() {
            let medal = i == 0 ? "🥇" : i == 1 ? "🥈" : i == 2 ? "🥉" : "▫️"
            msg += "\(medal) \(p.name): \(p.qty) unidades\n"
        }
        let leader = tops[0]
        let price = s.catalogProducts.first { $0.name == leader.name }?.price ?? 0
        msg += "\n💡 **\(leader.name)** genera aprox. Bs. \(Int(Double(leader.qty) * price)) en ventas. ¡Tu producto bandera!"
        return msg
    }

    private static func comboRecommendation(_ s: AppState) -> String {
        let active = s.combos.filter { $0.isActive }
        if !active.isEmpty {
            let list = active.map { "\($0.emoji) **\($0.name)** — Bs. \(Int($0.finalPrice)) (ahorra Bs. \(Int($0.saving)))" }.joined(separator: "\n")
            return "🎁 **Tus combos activos:**\n\(list)\n\n💡 Promociónales en hora pico para subir tu ticket promedio. Los combos pueden aumentar tus ventas hasta un 30%."
        }
        let prods = s.catalogProducts.filter { $0.isActive }
        if prods.count >= 2 {
            let p1 = prods[0]; let p2 = prods[1]
            let regular = p1.price + p2.price
            let comboPrice = regular * 0.85
            return "💡 **Recomendación de combo:**\nCombina **\(p1.name) + \(p2.name)**\n• Precio regular: Bs. \(Int(regular))\n• Precio sugerido: Bs. \(Int(comboPrice)) (15% descuento)\n• Atractivo para clientes que buscan valor\n\nCrea este combo desde el Catálogo → Combos 🎁"
        }
        return "🎁 Agrega más productos al catálogo para que pueda recomendarte combos personalizados."
    }

    private static func pricingAdvice(_ s: AppState) -> String {
        let active = s.catalogProducts.filter { $0.isActive }
        if active.isEmpty { return "💰 Primero agrega productos al catálogo para darte consejos de precio." }
        var msg = "💰 **Análisis de precios actuales:**\n"
        for p in active.prefix(5) {
            let suggestion = suggestPrice(p)
            msg += "• \(p.emoji) **\(p.name)**: Bs. \(Int(p.price)) — \(suggestion)\n"
        }
        msg += "\n📊 Regla general: El margen mínimo debería ser 35-40% sobre el costo."
        return msg
    }

    private static func suggestPrice(_ p: CatalogProduct) -> String {
        switch p.category.lowercased() {
        case "bebida", "bebidas": return p.price < 5 ? "⚠️ Podrías subir a Bs. \(Int(p.price * 1.2))" : "✅ Precio competitivo"
        case "snack": return p.price < 6 ? "💡 Considera Bs. \(Int(p.price * 1.15))" : "✅ Bien posicionado"
        case "especial": return p.price < 30 ? "⚠️ Platos especiales valen más" : "✅ Precio correcto"
        default: return "✅ OK"
        }
    }

    private static func improvementTips(_ s: AppState) -> String {
        var tips: [String] = []
        let score = s.tinkaScore
        let combos = s.combos.filter { $0.isActive }
        let inactive = s.catalogProducts.filter { !$0.isActive }
        let week = s.weekSales

        if combos.isEmpty { tips.append("🎁 Crea al menos 1 combo — aumenta ticket promedio hasta 25%") }
        if !inactive.isEmpty { tips.append("🔄 Tienes \(inactive.count) producto(s) inactivos — ¿los reactivas?") }
        if score < 70 { tips.append("📱 Registra ventas cada día para subir tu Tinka Score") }
        if week < 500 { tips.append("📣 Considera ofrecer descuento especial los días de menos venta") }
        if s.catalogProducts.filter({ $0.isActive }).count < 5 {
            tips.append("📦 Amplía tu catálogo — más opciones = más ventas")
        }
        tips.append("💬 Pide a tus clientes frecuentes que recomienden tu local")

        var msg = "🚀 **Mis recomendaciones para Doña María:**\n"
        for (i, t) in tips.prefix(4).enumerated() { msg += "\(i+1). \(t)\n" }
        msg += "\nTu score actual es **\(score)/100** — \(score >= 80 ? "¡Nivel excelente! 🏆" : "sigamos mejorando juntas 💪")"
        return msg
    }

    private static func scoreAnalysis(_ s: AppState) -> String {
        let score = s.tinkaScore
        let level = score >= 85 ? "Élite 🏆" : score >= 70 ? "Avanzado ⭐" : score >= 55 ? "En crecimiento 📈" : "Iniciando 🌱"
        var breakdown = "📊 **Tinka Score: \(score)/100 — \(level)**\n\n"
        breakdown += "**¿Cómo se calcula?**\n"
        breakdown += "• Ventas semanales: \(min(Int(s.weekSales / 50), 30))/30 pts\n"
        breakdown += "• Consistencia diaria: \(min(countActiveDays(s) * 3, 20))/20 pts\n"
        breakdown += "• Utilidad estimada: \(min(Int(s.utilityEstimate / 40), 15))/15 pts\n"
        breakdown += "• Base: 40 pts (siempre)\n\n"
        if score < 70 { breakdown += "💡 Para subir: registra ventas todos los días y aumenta tus ingresos semanales." }
        else { breakdown += "🎯 ¡Vas excelente! Mantén el ritmo." }
        return breakdown
    }

    private static func profitAnalysis(_ s: AppState) -> String {
        let week = s.weekSales
        let month = s.monthSales
        let util = Int(s.utilityEstimate)
        let monthUtil = Int(month * 0.35)
        return "💵 **Análisis de ganancias:**\n• Esta semana: Bs. \(Int(week)) → Utilidad: **Bs. \(util)**\n• Este mes: Bs. \(Int(month)) → Utilidad: **Bs. \(monthUtil)**\n• Margen estimado: **35%**\n\n\(util > 500 ? "🏆 ¡Excelente margen esta semana!" : "💪 Sigue vendiendo para aumentar tu utilidad.")\n\n💡 Para mejorar el margen: sube el precio de productos con alta demanda o crea combos con mejor margen."
    }

    private static func catalogSummary(_ s: AppState) -> String {
        let active = s.catalogProducts.filter { $0.isActive }
        let inactive = s.catalogProducts.filter { !$0.isActive }
        let combos = s.combos.filter { $0.isActive }
        if active.isEmpty {
            return "📦 Tu catálogo está vacío. Ve al tab **Catálogo** y agrega tus productos para usar voz y ventas rápidas."
        }
        let list = active.map { "\($0.emoji) \($0.name) — Bs. \(Int($0.price))" }.joined(separator: "\n")
        var msg = "📦 **Tu catálogo activo (\(active.count) productos):**\n\(list)"
        if !inactive.isEmpty { msg += "\n\n⚠️ \(inactive.count) producto(s) inactivos" }
        if !combos.isEmpty { msg += "\n🎁 \(combos.count) combo(s) activos" }
        return msg
    }

    // MARK: - Helpers
    private static func matches(_ q: String, _ keywords: [String]) -> Bool {
        keywords.contains { q.contains($0) }
    }

    private static func countActiveDays(_ s: AppState) -> Int {
        let cal = Calendar.current
        var days = Set<Int>()
        for sale in s.sales {
            let d = cal.ordinality(of: .day, in: .era, for: sale.date) ?? 0
            days.insert(d)
        }
        return days.count
    }
}
