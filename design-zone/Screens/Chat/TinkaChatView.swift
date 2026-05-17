import SwiftUI

private struct SuggestedPrompt: Identifiable {
    let id = UUID(); let icon: String; let text: String
}

struct TinkaChatView: View {
    @EnvironmentObject var state: AppState
    @State private var inputText = ""
    @State private var isTyping = false
    @FocusState private var inputFocused: Bool
    @State private var scrollProxy: ScrollViewProxy? = nil

    private let prompts: [SuggestedPrompt] = [
        .init(icon: "chart.bar.fill", text: "¿Cómo va mi negocio?"),
        .init(icon: "creditcard.fill", text: "¿Puedo acceder a un microcrédito?"),
        .init(icon: "star.fill", text: "¿Qué producto vendo más?"),
        .init(icon: "arrow.up.circle.fill", text: "¿Cómo puedo mejorar mi score?")
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
                            if isTyping { typingIndicator }
                            Color.clear.frame(height: 8).id("bottom")
                        }
                        .padding(.horizontal, 16).padding(.top, 12)
                    }
                    .onChange(of: state.chatMessages.count) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                    .onChange(of: isTyping) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
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
            Circle().fill(TinkaColor.royalPurple.opacity(0.15)).frame(width: 300).blur(radius: 80).offset(x: 150, y: -200)
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
                Button { state.chatMessages.removeAll() } label: {
                    Image(systemName: "trash").font(.system(size: 14)).foregroundColor(TinkaColor.subtleText)
                        .padding(8).background(Color.white.opacity(0.7)).clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(LinearGradient.tinkaPrimary.opacity(0.12)).frame(width: 100, height: 100)
                Image(systemName: "sparkles").font(.system(size: 40)).foregroundColor(TinkaColor.magenta)
            }
            Text("¡Hola, Doña María!").font(.tinka(22, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
            Text("Soy Tinka, tu copiloto financiero.\nPregúntame lo que necesites sobre tu negocio.").font(.tinka(14)).foregroundColor(TinkaColor.subtleText).multilineTextAlignment(.center)
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
                            .shadow(color: TinkaColor.royalPurple.opacity(0.06), radius: 4, y: 2)
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
            TextField("Pregúntale a Tinka...", text: $inputText)
                .font(.tinka(14)).focused($inputFocused)
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color.white.opacity(0.85)).clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(TinkaColor.cardStroke))
            Button { sendMessage(inputText) } label: {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 36))
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? AnyShapeStyle(Color.gray.opacity(0.4)) : AnyShapeStyle(LinearGradient.tinkaPrimary))
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var typingIndicator: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle().fill(LinearGradient.tinkaPrimary).frame(width: 32, height: 32)
                Image(systemName: "sparkles").font(.system(size: 12)).foregroundColor(.white)
            }
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle().fill(TinkaColor.subtleText).frame(width: 7, height: 7)
                        .opacity(0.6).animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(i) * 0.2), value: isTyping)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color.white.opacity(0.9)).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer()
        }
    }

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        inputText = ""
        inputFocused = false
        withAnimation {
            state.chatMessages.append(ChatMessage(text: trimmed, isUser: true, timestamp: Date()))
        }
        isTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            let reply = generateReply(for: trimmed)
            withAnimation {
                isTyping = false
                state.chatMessages.append(ChatMessage(text: reply, isUser: false, timestamp: Date()))
            }
        }
    }

    private func generateReply(for question: String) -> String {
        let q = question.lowercased()
        let score = state.tinkaScore
        let today = state.todaySales
        let week = state.weekSales
        let topProd = state.topProduct
        let status = state.financialStatus
        let ticket = Int(state.averageTicket)
        let utility = Int(state.utilityEstimate)

        if q.contains("negocio") || q.contains("cómo va") || q.contains("como va") || q.contains("resumen") {
            return "📊 Tu negocio está \(status.lowercased()), Doña María. Esta semana llevas Bs. \(Int(week)) en ventas, con utilidad estimada de Bs. \(utility). Tu Tinka Score es \(score)/100. \(score >= 75 ? "¡Sigue así! 💪" : "¡Cada venta cuenta! 🚀")"
        }
        if q.contains("crédito") || q.contains("microcrédito") || q.contains("prestamo") || q.contains("préstamo") {
            let eligible = score >= 60
            return eligible
                ? "💳 ¡Buenas noticias! Con tu Tinka Score de \(score)/100 y ventas constantes, eres candidata ideal para un microcrédito. Puedes acceder a montos desde Bs. 2.000 hasta Bs. 15.000. Ve a la sección Crédito para simular tu préstamo. 🎯"
                : "💳 Tu Tinka Score actual es \(score)/100. Necesitas al menos 60 puntos para calificar. Sigue registrando ventas diariamente y llegarás pronto. 📈"
        }
        if q.contains("producto") || q.contains("vendo más") || q.contains("mejor") {
            return "⭐ Tu producto estrella es **\(topProd)** — es el más vendido en tu historial. El ticket promedio es Bs. \(ticket). ¡Considera preparar más en los días de mayor demanda! 🫓"
        }
        if q.contains("score") || q.contains("mejorar") || q.contains("puntaje") {
            return "📈 Tu Tinka Score actual es \(score)/100. Para mejorarlo: 1️⃣ Registra todas tus ventas diariamente, 2️⃣ Mantén constancia en registros, 3️⃣ Aumenta tu promedio diario. \(score >= 85 ? "¡Estás en nivel Platino! 🏆" : "¡Vas muy bien! 💪")"
        }
        if q.contains("hoy") || q.contains("día") {
            return today > 0
                ? "📅 Hoy llevas Bs. \(Int(today)) en ventas con \(state.todaySaleCount) venta(s) registradas. Tu estado financiero de hoy es: **\(status)**. \(today >= 300 ? "¡Excelente día! 🌟" : "¡Sigue vendiendo! 💪")"
                : "📅 Aún no has registrado ventas hoy. ¡Empieza ahora con el botón Voz o Ventas! 🎤"
        }
        return "🤔 Basándome en tus datos: llevas Bs. \(Int(today)) hoy y Bs. \(Int(week)) esta semana. Tu score es \(score)/100. ¿Puedo ayudarte con algo más específico? 😊"
    }
}

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
                Text(message.text).font(.tinka(14)).foregroundColor(message.isUser ? .white : TinkaColor.darkNavy)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(message.isUser ? LinearGradient.tinkaPrimary : LinearGradient(colors: [Color.white.opacity(0.95)], startPoint: .leading, endPoint: .trailing))
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

#Preview { TinkaChatView().environmentObject(AppState.shared) }
