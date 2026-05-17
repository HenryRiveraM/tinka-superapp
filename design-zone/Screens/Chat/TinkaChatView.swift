import SwiftUI

private struct SuggestedPrompt: Identifiable {
    let id = UUID(); let icon: String; let text: String
}

struct TinkaChatView: View {
    @EnvironmentObject var state: AppState
    @State private var inputText = ""
    @State private var isTyping = false
    @State private var showApiKeySetup = false
    @State private var apiKeyInput = ""
    @State private var aiError: String? = nil
    @FocusState private var inputFocused: Bool

    private let prompts: [SuggestedPrompt] = [
        .init(icon: "chart.bar.fill",       text: "¿Cómo va mi negocio?"),
        .init(icon: "star.fill",            text: "¿Cuál es mi producto estrella?"),
        .init(icon: "tag.fill",             text: "¿Qué combo debería crear?"),
        .init(icon: "calendar.badge.clock", text: "Dame un resumen de hoy"),
        .init(icon: "arrow.up.circle.fill", text: "¿Qué puedo mejorar?"),
        .init(icon: "lightbulb.fill",       text: "¿Estoy vendiendo bien esta semana?")
    ]

    private var hasApiKey: Bool {
        let k = UserDefaults.standard.string(forKey: "tinka_gemini_key") ?? ""
        return !k.isEmpty
    }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                chatHeader
                if !hasApiKey {
                    apiKeyBanner
                }
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            if state.chatMessages.isEmpty { emptyState }
                            ForEach(state.chatMessages) { msg in ChatBubble(message: msg).id(msg.id) }
                            if isTyping { typingIndicator.id("typing") }
                            if let err = aiError { errorBubble(err).id("error") }
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
        .sheet(isPresented: $showApiKeySetup) { apiKeySheet }
    }

    // MARK: - Views

    private var background: some View {
        ZStack {
            LinearGradient.tinkaSoftBackground.ignoresSafeArea()
            Circle().fill(TinkaColor.royalPurple.opacity(0.12)).frame(width: 300).blur(radius: 80).offset(x: 150, y: -200)
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
                    Circle().fill(hasApiKey ? TinkaColor.green : TinkaColor.yellow).frame(width: 7, height: 7)
                    Text(hasApiKey ? "Gemini · En línea" : "Modo local")
                        .font(.tinka(12)).foregroundColor(TinkaColor.subtleText)
                }
            }
            Spacer()
            HStack(spacing: 8) {
                Button { showApiKeySetup = true } label: {
                    Image(systemName: "key.fill")
                        .font(.system(size: 13)).foregroundColor(TinkaColor.subtleText)
                        .padding(8).background(Color.white.opacity(0.7)).clipShape(Circle())
                }
                if !state.chatMessages.isEmpty {
                    Button { withAnimation { state.chatMessages.removeAll(); aiError = nil } } label: {
                        Image(systemName: "trash").font(.system(size: 13)).foregroundColor(TinkaColor.subtleText)
                            .padding(8).background(Color.white.opacity(0.7)).clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 12).background(.ultraThinMaterial)
    }

    private var apiKeyBanner: some View {
        Button { showApiKeySetup = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles").foregroundStyle(LinearGradient.tinkaPrimary).font(.system(size: 16))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Activa IA real con Gemini").font(.tinka(13, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                    Text("Toca aquí para configurar tu API key gratuita").font(.tinka(11)).foregroundColor(TinkaColor.subtleText)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
            }
            .padding(.horizontal, 18).padding(.vertical, 10)
            .background(TinkaColor.yellow.opacity(0.12))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(LinearGradient.tinkaPrimary.opacity(0.12)).frame(width: 100, height: 100)
                Image(systemName: "sparkles").font(.system(size: 40)).foregroundColor(TinkaColor.magenta)
            }
            Text("¡Hola, Doña María!").font(.tinka(22, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
            Text(hasApiKey
                ? "Soy Tinka IA con Gemini.\nPregúntame lo que necesites sobre tu negocio."
                : "Soy Tinka, tu copiloto financiero.\nPregúntame lo que necesites sobre tu negocio."
            )
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

    @ViewBuilder
    private func errorBubble(_ msg: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(TinkaColor.yellow)
            Text(msg).font(.tinka(13)).foregroundColor(TinkaColor.darkNavy)
            Spacer()
            Button { aiError = nil } label: {
                Image(systemName: "xmark").font(.system(size: 12, weight: .bold))
                    .foregroundColor(TinkaColor.subtleText)
            }
        }
        .padding(12)
        .background(TinkaColor.yellow.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(TinkaColor.yellow.opacity(0.3)))
        .transition(.opacity)
    }

    // MARK: - API Key Sheet

    private var apiKeySheet: some View {
        NavigationView {
            ZStack {
                LinearGradient.tinkaSoftBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle().fill(LinearGradient.tinkaPrimary.opacity(0.12)).frame(width: 80, height: 80)
                            Image(systemName: "sparkles").font(.system(size: 34)).foregroundColor(TinkaColor.magenta)
                        }
                        Text("Activa Gemini IA").font(.tinka(22, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                        Text("Obtén tu API key gratuita en ai.google.dev y pégala aquí para activar la IA real en tu negocio.")
                            .font(.tinka(14)).foregroundColor(TinkaColor.subtleText).multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gemini API Key").font(.tinka(13, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
                        SecureField("AIza...", text: $apiKeyInput)
                            .font(.system(size: 14, weight: .regular, design: .monospaced)).foregroundColor(TinkaColor.darkNavy)
                            .padding(14)
                            .background(Color.white.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(TinkaColor.cardStroke))
                    }

                    Button {
                        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty {
                            UserDefaults.standard.set(trimmed, forKey: "tinka_gemini_key")
                            Task { await GeminiService.shared.setApiKey(trimmed) }
                            showApiKeySetup = false
                            apiKeyInput = ""
                        }
                    } label: {
                        Text("Activar Gemini IA")
                            .font(.tinka(16, weight: .bold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(16)
                            .background(apiKeyInput.count > 10 ? AnyShapeStyle(LinearGradient.tinkaPrimary) : AnyShapeStyle(Color.gray.opacity(0.4)))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(apiKeyInput.count <= 10)

                    if hasApiKey {
                        Button {
                            UserDefaults.standard.removeObject(forKey: "tinka_gemini_key")
                            Task { await GeminiService.shared.setApiKey("") }
                            showApiKeySetup = false
                        } label: {
                            Text("Eliminar API Key")
                                .font(.tinka(14)).foregroundColor(TinkaColor.red)
                        }
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Configuración IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showApiKeySetup = false }.foregroundColor(TinkaColor.subtleText)
                }
            }
        }
        .onAppear {
            apiKeyInput = UserDefaults.standard.string(forKey: "tinka_gemini_key") ?? ""
        }
    }

    // MARK: - Logic

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isTyping else { return }
        inputText = ""
        inputFocused = false
        aiError = nil
        withAnimation { state.chatMessages.append(ChatMessage(text: trimmed, isUser: true)) }
        isTyping = true

        let context = state.businessContextForAI
        let storedKey = UserDefaults.standard.string(forKey: "tinka_gemini_key") ?? ""

        if storedKey.isEmpty {
            // Fallback to local AI
            let delay = Double.random(in: 1.0...1.8)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let reply = TinkaAIFallback.reply(for: trimmed, state: state)
                withAnimation { isTyping = false; state.chatMessages.append(ChatMessage(text: reply, isUser: false)) }
            }
        } else {
            Task {
                await GeminiService.shared.setApiKey(storedKey)
                do {
                    let reply = try await GeminiService.shared.chat(userMessage: trimmed, businessContext: context)
                    await MainActor.run {
                        withAnimation { isTyping = false; state.chatMessages.append(ChatMessage(text: reply, isUser: false)) }
                    }
                } catch {
                    await MainActor.run {
                        isTyping = false
                        aiError = error.localizedDescription
                        // Fallback if Gemini fails
                        let fallback = TinkaAIFallback.reply(for: trimmed, state: state)
                        withAnimation { state.chatMessages.append(ChatMessage(text: fallback, isUser: false)) }
                    }
                }
            }
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

// MARK: - Local Fallback AI (when no API key)
enum TinkaAIFallback {
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

        if q.contains("hoy") || q.contains("día") || q.contains("resumen") {
            if today == 0 {
                return "📅 Aún no has registrado ventas hoy, Doña María. ¡Empieza ahora con el micrófono 🎤 o la venta rápida!"
            }
            return "📅 Hoy llevas **Bs. \(Int(today))** en \(todayCount) venta(s). Utilidad estimada: **Bs. \(Int(today * 0.35))**. Estado: **\(status)**. \(today >= 300 ? "¡Excelente día! 🌟" : "¡Sigue adelante! 💪")"
        }
        if q.contains("negocio") || q.contains("cómo va") || q.contains("como va") {
            return "📊 Tu negocio está **\(status)**. Esta semana: **Bs. \(Int(week))** en \(weekCount) ventas. Utilidad: **Bs. \(utility)**. Producto estrella: **\(topProd)**. Score: **\(score)/100**."
        }
        if q.contains("combo") || q.contains("promoción") || q.contains("promocion") {
            let activeProds = state.catalogProducts.filter { $0.isActive }.prefix(3).map { $0.name }.joined(separator: ", ")
            return "💡 Para crear un combo rentable, combina tus productos más vendidos. Tienes: \(activeProds). Ve a la tab Catálogo → Combos para crear tu primera promoción. ¡Los combos pueden subir tu ticket promedio un 20%!"
        }
        if q.contains("producto") || q.contains("estrella") || q.contains("vendo más") {
            let price = Int(state.catalogProducts.first { $0.name == topProd }?.price ?? 5)
            return "⭐ Tu producto más vendido es **\(topProd)** (Bs. \(price) c/u). Ticket promedio: **Bs. \(ticket)**. Asegúrate de tener siempre stock disponible."
        }
        if q.contains("score") || q.contains("puntaje") {
            let tip = score >= 75 ? "¡Vas excelente! 🏆" : "Registra ventas todos los días para subir más. 📈"
            return "📈 Tu Tinka Score es **\(score)/100**. \(tip)"
        }
        if q.contains("mejorar") || q.contains("consejo") || q.contains("tip") || q.contains("semana") {
            return "💡 Recomendaciones:\n1️⃣ Usa el micrófono 🎤 para registrar cada venta\n2️⃣ Revisa tu reporte semanal\n3️⃣ Ticket prom: Bs. \(ticket) — crea combos para subirlo\n4️⃣ **\(topProd)** es tu estrella, asegura su stock"
        }
        if q.contains("utilidad") || q.contains("ganancia") {
            return "💵 Utilidad estimada esta semana: **Bs. \(utility)** (35% de Bs. \(Int(week))). Hoy: **Bs. \(Int(today * 0.35))**. \(utility > 200 ? "¡Muy buen margen! 🌟" : "Sigue vendiendo. 💪")"
        }
        return "🤖 Hola Doña María. Hoy: **Bs. \(Int(today))**, semana: **Bs. \(Int(week))**. Score: **\(score)/100**. Estrella: **\(topProd)**. Activa Gemini IA para respuestas más inteligentes 🔑"
    }
}

#Preview { TinkaChatView().environmentObject(AppState.shared) }
