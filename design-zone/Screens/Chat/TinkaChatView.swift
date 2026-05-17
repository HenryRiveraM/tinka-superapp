import SwiftUI

private struct SuggestedPrompt: Identifiable {
    let id = UUID(); let icon: String; let text: String
}

struct TinkaChatView: View {
    @EnvironmentObject var state: AppState
    @State private var inputText = ""
    @State private var isTyping = false
    @State private var errorMessage: String? = nil
    @FocusState private var inputFocused: Bool

    private let prompts: [SuggestedPrompt] = [
        .init(icon: "chart.bar.fill",       text: "¿Cómo va mi negocio?"),
        .init(icon: "star.fill",            text: "¿Cuál es mi producto estrella?"),
        .init(icon: "tag.fill",             text: "¿Qué combo me recomiendas crear?"),
        .init(icon: "calendar.badge.clock", text: "Dame un resumen de hoy"),
        .init(icon: "arrow.up.circle.fill", text: "¿Cómo mejorar mi score?"),
        .init(icon: "lightbulb.fill",       text: "¿Estoy vendiendo bien esta semana?")
    ]

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                chatHeader
                messagesArea
                if state.chatMessages.isEmpty { suggestedPromptsBar }
                inputBar
                Color.clear.frame(height: 90)
            }
        }
    }

    // MARK: - Background
    private var background: some View {
        ZStack {
            LinearGradient.tinkaSoftBackground.ignoresSafeArea()
            Circle().fill(TinkaColor.royalPurple.opacity(0.12))
                .frame(width: 300).blur(radius: 80).offset(x: 150, y: -200)
        }
    }

    // MARK: - Header
    private var chatHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(LinearGradient.tinkaPrimary).frame(width: 44, height: 44)
                Image(systemName: "sparkles").font(.system(size: 18)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Tinka IA").font(.tinka(18, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                HStack(spacing: 5) {
                    Circle().fill(TinkaColor.green).frame(width: 7, height: 7)
                    Text("Gemini · En línea").font(.tinka(12)).foregroundColor(TinkaColor.subtleText)
                }
            }
            Spacer()
            if !state.chatMessages.isEmpty {
                Button {
                    withAnimation { state.chatMessages.removeAll(); errorMessage = nil }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13)).foregroundColor(TinkaColor.subtleText)
                        .padding(8).background(Color.white.opacity(0.7)).clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Messages Area
    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if state.chatMessages.isEmpty { emptyState }
                    ForEach(state.chatMessages) { msg in
                        ChatBubble(message: msg).id(msg.id)
                    }
                    if isTyping { typingIndicator.id("typing") }
                    if let err = errorMessage { errorBubble(err).id("err") }
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
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(LinearGradient.tinkaPrimary.opacity(0.12)).frame(width: 100, height: 100)
                Image(systemName: "sparkles").font(.system(size: 40)).foregroundColor(TinkaColor.magenta)
            }
            Text("¡Hola, Doña María!").font(.tinka(22, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
            Text("Soy Tinka IA, tu copiloto de negocios.\nPregúntame lo que necesites.")
                .font(.tinka(14)).foregroundColor(TinkaColor.subtleText).multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    // MARK: - Suggested Prompts
    private var suggestedPromptsBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preguntas frecuentes")
                .font(.tinka(12, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
                .padding(.horizontal, 18)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(prompts) { p in
                        Button { sendMessage(p.text) } label: {
                            HStack(spacing: 6) {
                                Image(systemName: p.icon)
                                    .font(.system(size: 12)).foregroundColor(TinkaColor.magenta)
                                Text(p.text)
                                    .font(.tinka(13)).foregroundColor(TinkaColor.darkNavy)
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

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Pregúntale a Tinka...", text: $inputText, axis: .vertical)
                .font(.tinka(14)).focused($inputFocused)
                .lineLimit(1...3)
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color.white.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(TinkaColor.cardStroke))
            Button { sendMessage(inputText) } label: {
                let isEmpty = inputText.trimmingCharacters(in: .whitespaces).isEmpty
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(isEmpty
                        ? AnyShapeStyle(Color.gray.opacity(0.35))
                        : AnyShapeStyle(LinearGradient.tinkaPrimary))
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isTyping)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Typing Indicator
    private var typingIndicator: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle().fill(LinearGradient.tinkaPrimary).frame(width: 32, height: 32)
                Image(systemName: "sparkles").font(.system(size: 12)).foregroundColor(.white)
            }
            TypingDots()
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer()
        }
    }

    @ViewBuilder
    private func errorBubble(_ msg: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash").foregroundColor(TinkaColor.yellow)
            Text(msg).font(.tinka(12)).foregroundColor(TinkaColor.darkNavy)
            Spacer()
            Button { withAnimation { errorMessage = nil } } label: {
                Image(systemName: "xmark").font(.system(size: 11, weight: .bold))
                    .foregroundColor(TinkaColor.subtleText)
            }
        }
        .padding(10)
        .background(TinkaColor.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(TinkaColor.yellow.opacity(0.3)))
        .transition(.opacity)
    }

    // MARK: - Send Logic
    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isTyping else { return }
        inputText = ""
        inputFocused = false
        errorMessage = nil
        withAnimation { state.chatMessages.append(ChatMessage(text: trimmed, isUser: true)) }
        isTyping = true

        let context = state.businessContextForAI

        Task {
            do {
                let reply = try await GeminiService.shared.chat(
                    userMessage: trimmed,
                    businessContext: context
                )
                await MainActor.run {
                    withAnimation {
                        isTyping = false
                        state.chatMessages.append(ChatMessage(text: reply, isUser: false))
                    }
                }
            } catch {
                NSLog("[Tinka Chat] AI failed, using local fallback: \(error.localizedDescription)")
                let fallback = TinkaLocalAI.reply(for: trimmed, state: state)
                await MainActor.run {
                    withAnimation {
                        isTyping = false
                        state.chatMessages.append(ChatMessage(text: fallback, isUser: false))
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
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(i) * 0.18),
                        value: phase
                    )
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
            if !message.isUser { aiAvatar }
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.tinka(14))
                    .foregroundColor(message.isUser ? .white : TinkaColor.darkNavy)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(message.isUser
                        ? AnyShapeStyle(LinearGradient.tinkaPrimary)
                        : AnyShapeStyle(Color.white.opacity(0.95)))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: message.isUser
                        ? TinkaColor.magenta.opacity(0.2)
                        : Color.black.opacity(0.05),
                        radius: 6, y: 3)
                Text(message.timestamp, style: .time)
                    .font(.tinka(10)).foregroundColor(TinkaColor.subtleText)
            }
            if message.isUser { Spacer(minLength: 48) }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.85).combined(with: .opacity),
            removal: .opacity
        ))
    }

    private var aiAvatar: some View {
        ZStack {
            Circle().fill(LinearGradient.tinkaPrimary).frame(width: 32, height: 32)
            Image(systemName: "sparkles").font(.system(size: 12)).foregroundColor(.white)
        }
    }
}

#Preview { TinkaChatView().environmentObject(AppState.shared) }
