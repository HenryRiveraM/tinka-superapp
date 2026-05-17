import SwiftUI

private struct SuggestedPrompt: Identifiable {
    let id = UUID(); let icon: String; let text: String
}

struct TinkaChatView: View {
    @EnvironmentObject var state: AppState
    @State private var inputText = ""
    @State private var isTyping = false
    @FocusState private var inputFocused: Bool

    private let prompts: [SuggestedPrompt] = [
        .init(icon: "chart.bar.fill",          text: "¿Cómo va mi negocio?"),
        .init(icon: "star.fill",               text: "¿Cuál es mi producto estrella?"),
        .init(icon: "arrow.up.circle.fill",    text: "¿Cómo puedo mejorar mi score?"),
        .init(icon: "calendar.badge.clock",    text: "Dame un resumen de hoy"),
        .init(icon: "creditcard.fill",         text: "¿Puedo acceder a un microcrédito?"),
        .init(icon: "lightbulb.fill",          text: "¿Qué puedo mejorar en mi negocio?")
    ]

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                chatHeader
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            if state.chatMessages.isEmpty { emptyState }
                            ForEach(state.chatMessages) { msg in ChatBubble(message: msg).id(msg.id) }
                            if isTyping { typingIndicator.id("typing") }
                            Color.clear.frame(height: 8).id("bottom")
                        }
                        .padding(.horizontal, 16).padding(.top, 12)
                    }
                    .onChange(of: state.chatMessages.count) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                    .onChange(of: isTyping) { _, v in
                        if v { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
                    }
                }
                if state.chatMessages.isEmpty { suggestedPromptsBar }
                inputBar
                Color.clear.frame(height: 90)
            }
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient.tinkaSoftBackground.ignoresSafeArea()
            Circle().fill(TinkaColor.royalPurple.opacity(0.13)).frame(width: 300).blur(radius: 80).offset(x: 150, y: -200)
        }
    }

    private var chatHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(LinearGradient.tinkaPrimary).frame(width: 44, height: 44)
                Image(systemName: "sparkles").font(.system(size: 18)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Tinka IA").font(.tinka(18, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                HStack(spacing: 4) {
                    Circle().fill(TinkaColor.green).frame(width: 7, height: 7)
                    Text("Tu copiloto financiero").font(.tinka(12)).foregroundColor(TinkaColor.subtleText)
                }
            }
            Spacer()
            if !state.chatMessages.isEmpty {
                Button { withAnimation { state.chatMessages.removeAll() } } label: {
                    Image(systemName: "trash").font(.system(size: 14)).foregroundColor(TinkaColor.subtleText)
                        .padding(8).background(Color.white.opacity(0.7)).clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 12).background(.ultraThinMaterial)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(LinearGradient.tinkaPrimary.opacity(0.12)).frame(width: 100, height: 100)
                Image(systemName: "sparkles").font(.system(size: 40)).foregroundColor(TinkaColor.magenta)
            }
            Text("¡Hola, Doña María!").font(.tinka(22, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
            Text("Soy Tinka, tu copiloto financiero.\nPregúntame lo que necesites sobre tu negocio.")
                .font(.tinka(14)).foregroundColor(TinkaColor.subtleText).multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    private var suggestedPromptsBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preguntas frecuentes").font(.tinka(12, weight: .semibold)).foregroundColor(TinkaColor.subtleText).padding(.horizontal, 18)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(prompts) { p in
                        Button { sendMessage(p.text) } label: {
                            HStack(spacing: 6) {
                                Image(systemName: p.icon).font(.system(size: 12)).foregroundColor(TinkaColor.magenta)
                                Text(p.text).font(.tinka(13)).foregroundColor(TinkaColor.darkNavy)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(Color.white.opacity(0.85)).clipShape(Capsule())
                            .overlay(Capsule().stroke(TinkaColor.cardStroke))
                        }
                    }
                }
                .padding(.horizontal, 18)
            }
        }
        .padding(.bottom, 8)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Pregúntale a Tinka...", text: $inputText, axis: .vertical)
                .font(.tinka(14)).focused($inputFocused)
                .lineLimit(1...3)
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color.white.opacity(0.85)).clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(TinkaColor.cardStroke))
            Button { sendMessage(inputText) } label: {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 36))
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty
                        ? AnyShapeStyle(Color.gray.opacity(0.35))
                        : AnyShapeStyle(LinearGradient.tinkaPrimary))
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isTyping)
        }
        .padding(.horizontal, 16).padding(.vertical, 10).background(.ultraThinMaterial)
    }

    private var typingIndicator: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle().fill(LinearGradient.tinkaPrimary).frame(width: 32, height: 32)
                Image(systemName: "sparkles").font(.system(size: 12)).foregroundColor(.white)
            }
            TypingDots()
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color.white.opacity(0.9)).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer()
        }
    }

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isTyping else { return }
        inputText = ""
        inputFocused = false
        withAnimation { state.chatMessages.append(ChatMessage(text: trimmed, isUser: true)) }
        isTyping = true
        let delay = Double.random(in: 1.2...2.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let reply = TinkaAI.reply(for: trimmed, state: state)
            withAnimation { isTyping = false; state.chatMessages.append(ChatMessage(text: reply, isUser: false)) }
        }
    }
}

// MARK: - Typing Dots
struct TypingDots: View {
    @State private var phase = false
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(TinkaColor.subtleText).frame(width: 7, height: 7)
                    .scaleEffect(phase ? 1.0 : 0.5).opacity(phase ? 1 : 0.3)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(i) * 0.18), value: phase)
            }
        }
        .onAppear { phase = true }
    }
}

// MARK: - Chat Bubble
struct ChatBubble: View {
    let message: ChatMessage
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isUser {
                ZStack {
                    Circle().fill(LinearGradient.tinkaPrimary).frame(width: 32, height: 32)
                    Image(systemName: "sparkles").font(.system(size: 12)).foregroundColor(.white)
                }
            }
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.tinka(14))
                    .foregroundColor(message.isUser ? .white : TinkaColor.darkNavy)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(message.isUser
                        ? AnyShapeStyle(LinearGradient.tinkaPrimary)
                        : AnyShapeStyle(Color.white.opacity(0.95)))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: message.isUser ? TinkaColor.magenta.opacity(0.2) : Color.black.opacity(0.05), radius: 6, y: 3)
                Text(message.timestamp, style: .time).font(.tinka(10)).foregroundColor(TinkaColor.subtleText)
            }
            if message.isUser { Spacer(minLength: 48) }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .transition(.asymmetric(insertion: .scale(scale: 0.85).combined(with: .opacity), removal: .opacity))
    }
}

// MARK: - Tinka AI Engine
enum TinkaAI {
    static func reply(for question: String, state: AppState) -> String {
        let q = question.lowercased()
        let score = state.tinkaScore
        let today = state.todaySales
        let todayCount = state.todaySaleCount
        let week = state.weekSales
        let weekCount = state.weekSaleCount
        let topProd = state.topProduct
        let status = state.financialStatus
        let ticket = Int(state.averageTicket)
        let utility = Int(state.utilityEstimate)

        // Resumen de hoy
        if q.contains("hoy") || q.contains("día") || q.contains("resumen") {
            if today == 0 {
                return "📅 Aún no has registrado ventas hoy, Doña María. ¡Empieza ahora con el botón Voz 🎤 o la venta rápida! Cada venta suma a tu score."
            }
            return "📅 Hoy llevas **Bs. \(Int(today))** en \(todayCount) venta(s). Tu utilidad estimada es **Bs. \(Int(today * 0.35))**. Estado financiero: **\(status)**. \(today >= 300 ? "¡Excelente día! 🌟" : today >= 100 ? "Buen ritmo, sigue vendiendo 💪" : "Tienes potencial para más, ¡ánimo! 🚀")"
        }

        // Negocio / cómo va
        if q.contains("negocio") || q.contains("cómo va") || q.contains("como va") {
            return "📊 Tu negocio está **\(status)**, Doña María. Esta semana: **Bs. \(Int(week))** en \(weekCount) ventas. Utilidad estimada: **Bs. \(utility)**. Tu producto estrella es **\(topProd)**. Tinka Score: **\(score)/100**. \(score >= 75 ? "¡Vas excelente! 🏆" : "¡Sigue registrando para mejorar! 💪")"
        }

        // Producto estrella
        if q.contains("producto") || q.contains("estrella") || q.contains("vendo más") || q.contains("mejor producto") {
            let price = Int(ProductCatalog.prices[topProd] ?? 0)
            return "⭐ Tu producto más vendido es **\(topProd)** (Bs. \(price) c/u). Ticket promedio actual: **Bs. \(ticket)**. Considera preparar más en los horarios de mayor demanda para maximizar tus ventas."
        }

        // Score / mejorar score
        if q.contains("score") || q.contains("puntaje") || q.contains("mejorar score") {
            let tips = score >= 85 ? "¡Estás en nivel Platino! Mantén tu constancia. 🏆" :
                       score >= 70 ? "Para subir más: registra TODAS tus ventas diariamente y mantén constancia. 📈" :
                       "Para mejorar rápido: 1️⃣ Registra ventas todos los días, 2️⃣ Apunta al menos Bs. 150/día, 3️⃣ Usa el micrófono para no olvidar ninguna venta."
            return "📈 Tu Tinka Score actual es **\(score)/100**. \(tips)"
        }

        // Microcrédito
        if q.contains("crédito") || q.contains("microcrédito") || q.contains("préstamo") || q.contains("prestamo") {
            return score >= 60
                ? "💳 ¡Buenas noticias! Con Score **\(score)/100** y ventas de **Bs. \(Int(week))** esta semana, calificas para microcrédito hasta **Bs. 15,000** con Banco FIE. Ve a la tab de Crédito para simular tu cuota. 🎯"
                : "💳 Tu Score actual es **\(score)/100**. Necesitas al menos 60 pts para calificar. Sigue registrando ventas diariamente — en pocos días podrás acceder. 📈"
        }

        // Mejorar negocio / consejos
        if q.contains("mejorar") || q.contains("consejo") || q.contains("tip") || q.contains("recomendación") {
            return "💡 Mis recomendaciones para \(today == 0 ? "empezar bien el día" : "mejorar tus ventas"):\n1️⃣ Usa el micrófono 🎤 para registrar cada venta al momento\n2️⃣ Revisa tu reporte semanal cada domingo\n3️⃣ Tu ticket prom. es Bs. \(ticket) — ofrece combos para subirlo\n4️⃣ \(topProd) es tu estrella, ¡prioriza su stock!"
        }

        // Utilidad / ganancias
        if q.contains("utilidad") || q.contains("ganancia") || q.contains("ingreso") {
            return "💵 Esta semana tu utilidad estimada es **Bs. \(utility)** (35% de Bs. \(Int(week)) en ventas). Hoy: **Bs. \(Int(today * 0.35))** de utilidad. \(utility > 200 ? "¡Muy buen margen! 🌟" : "Sigue vendiendo para aumentar tus ganancias. 💪")"
        }

        // Respuesta genérica con datos reales
        return "🤖 Hola Doña María. Hoy llevas **Bs. \(Int(today))** y esta semana **Bs. \(Int(week))**. Tu Score es **\(score)/100** y tu producto estrella es **\(topProd)**. ¿Quieres que te explique algo específico sobre tus ventas o finanzas? 😊"
    }
}

#Preview { TinkaChatView().environmentObject(AppState.shared) }
