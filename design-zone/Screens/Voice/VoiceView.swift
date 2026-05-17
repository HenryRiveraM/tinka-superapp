import SwiftUI
import Speech

enum VoiceFlowState { case idle, listening, processing, result }

struct VoiceView: View {
    @EnvironmentObject var state: AppState
    @StateObject private var speech = SpeechRecognizer()
    @State private var flowState: VoiceFlowState = .idle
    @State private var parsedProducts: [SaleProduct] = []
    @State private var pulseScale: CGFloat = 1.0
    @State private var showSuccess = false
    @State private var showPermissionAlert = false

    var parsedTotal: Double { parsedProducts.reduce(0) { $0 + $1.subtotal } }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                header
                Spacer()
                currentStateView
                Spacer()
                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 24)
            if showSuccess { successOverlay }
        }
        .onChange(of: speech.isListening) { _, isNow in
            if !isNow && flowState == .listening { finishListening() }
        }
        .onChange(of: speech.permissionDenied) { _, denied in
            if denied { showPermissionAlert = true }
        }
        .alert("Permisos requeridos", isPresented: $showPermissionAlert) {
            Button("Abrir Ajustes") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Tinka necesita acceso al micrófono y reconocimiento de voz. Ve a Ajustes > Tinka para activarlos.")
        }
    }

    // MARK: State routing
    @ViewBuilder private var currentStateView: some View {
        switch flowState {
        case .idle:       idleView
        case .listening:  listeningView
        case .processing: processingView
        case .result:     resultView
        }
    }

    // MARK: Background
    private var background: some View {
        ZStack {
            LinearGradient.tinkaSoftBackground.ignoresSafeArea()
            Circle().fill(TinkaColor.magenta.opacity(0.2)).frame(width: 350).blur(radius: 100).offset(y: -200)
            Circle().fill(TinkaColor.deepBlue.opacity(0.15)).frame(width: 300).blur(radius: 80).offset(x: -100, y: 200)
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Registro por Voz").font(.tinka(26, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
            Text("Habla y Tinka entiende").font(.tinka(14)).foregroundColor(TinkaColor.subtleText)
        }
        .padding(.top, 16)
    }

    // MARK: Idle
    private var idleView: some View {
        VStack(spacing: 32) {
            micButton
            VStack(spacing: 8) {
                Text("Toca el micrófono").font(.tinka(18, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
                Text("Di cosas como:\n\"Vendí tres salteñas y dos refrescos\"")
                    .font(.tinka(14)).foregroundColor(TinkaColor.subtleText).multilineTextAlignment(.center)
            }
            exampleChips
        }
    }

    // MARK: Listening
    private var listeningView: some View {
        VStack(spacing: 32) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle().stroke(TinkaColor.magenta.opacity(0.3 - Double(i)*0.08), lineWidth: 2)
                        .frame(width: 100 + CGFloat(i)*40, height: 100 + CGFloat(i)*40)
                        .scaleEffect(pulseScale)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(Double(i)*0.2), value: pulseScale)
                }
                micButton
            }
            .frame(width: 200, height: 200)
            VStack(spacing: 8) {
                Text("Escuchando...").font(.tinka(20, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
                if !speech.transcript.isEmpty {
                    Text(speech.transcript)
                        .font(.tinka(15)).foregroundColor(TinkaColor.subtleText)
                        .multilineTextAlignment(.center).padding(.horizontal, 16)
                        .animation(.easeIn, value: speech.transcript)
                }
            }
            WaveformView()
            Button("Detener") { speech.stopListening() }
                .font(.tinka(15, weight: .semibold)).foregroundColor(TinkaColor.magenta)
                .padding(.horizontal, 24).padding(.vertical, 12)
                .background(TinkaColor.magenta.opacity(0.1)).clipShape(Capsule())
                .overlay(Capsule().stroke(TinkaColor.magenta.opacity(0.3)))
        }
        .onAppear { pulseScale = 1.1 }
    }

    // MARK: Processing
    private var processingView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle().fill(LinearGradient.tinkaPrimary.opacity(0.15)).frame(width: 120, height: 120)
                Image(systemName: "sparkles").font(.system(size: 44)).foregroundColor(TinkaColor.magenta)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
            }
            VStack(spacing: 8) {
                Text("Analizando con IA...").font(.tinka(20, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
                Text("Tinka está parseando tu venta").font(.tinka(14)).foregroundColor(TinkaColor.subtleText)
            }
            ProgressView().tint(TinkaColor.magenta).scaleEffect(1.2)
        }
    }

    // MARK: Result
    private var resultView: some View {
        VStack(spacing: 20) {
            transcriptCard
            parsedCard
            resultActions
        }
    }

    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "quote.bubble.fill").foregroundColor(TinkaColor.deepBlue)
                Text("Dijiste:").font(.tinka(13, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
            }
            Text("\"\(speech.transcript)\"")
                .font(.tinka(16, weight: .medium)).foregroundColor(TinkaColor.darkNavy).italic()
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).glassCard(cornerRadius: 16)
    }

    private var parsedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill").foregroundColor(TinkaColor.green)
                Text("Tinka detectó:").font(.tinka(14, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
            }
            if parsedProducts.isEmpty {
                Text("No se detectaron productos. Intenta de nuevo.")
                    .font(.tinka(14)).foregroundColor(TinkaColor.subtleText)
            } else {
                ForEach(parsedProducts) { p in
                    HStack {
                        Text("• \(p.qty)x \(p.name)").font(.tinka(15)).foregroundColor(TinkaColor.darkNavy)
                        Spacer()
                        Text("Bs. \(p.subtotal, specifier: "%.0f")").font(.tinka(14, weight: .semibold)).foregroundColor(TinkaColor.deepBlue)
                    }
                }
                Divider()
                HStack {
                    Text("Total").font(.tinka(16, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                    Spacer()
                    Text("Bs. \(parsedTotal, specifier: "%.2f")").font(.tinka(20, weight: .bold)).foregroundColor(TinkaColor.magenta)
                }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).glassCard(cornerRadius: 16)
    }

    private var resultActions: some View {
        VStack(spacing: 12) {
            Button { confirmSale() } label: {
                Label("Confirmar venta", systemImage: "checkmark.circle.fill")
                    .font(.tinka(16, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(16)
                    .background(parsedProducts.isEmpty ? AnyShapeStyle(Color.gray.opacity(0.5)) : AnyShapeStyle(LinearGradient.tinkaPrimary))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: TinkaColor.magenta.opacity(0.3), radius: 10, y: 5)
            }
            .disabled(parsedProducts.isEmpty)
            HStack(spacing: 12) {
                Button { reset() } label: {
                    Text("Cancelar").font(.tinka(15, weight: .medium)).foregroundColor(TinkaColor.subtleText)
                        .frame(maxWidth: .infinity).padding(14)
                        .background(Color.white.opacity(0.7)).clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(TinkaColor.cardStroke))
                }
                Button { startListening() } label: {
                    Text("Reintentar").font(.tinka(15, weight: .medium)).foregroundColor(TinkaColor.deepBlue)
                        .frame(maxWidth: .infinity).padding(14)
                        .background(TinkaColor.deepBlue.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(TinkaColor.deepBlue.opacity(0.3)))
                }
            }
        }
    }

    // MARK: Mic button
    private var micButton: some View {
        Button { handleMicTap() } label: {
            ZStack {
                Circle().fill(LinearGradient.tinkaPrimary).frame(width: 90, height: 90)
                    .shadow(color: TinkaColor.magenta.opacity(0.45), radius: 20, y: 8)
                Image(systemName: flowState == .listening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 34, weight: .bold)).foregroundColor(.white)
            }
        }
        .scaleEffect(flowState == .listening ? 1.05 : 1.0)
        .animation(.spring(response: 0.4), value: flowState)
    }

    // MARK: Example chips
    private var exampleChips: some View {
        VStack(spacing: 8) {
            ForEach(["Vendí tres salteñas y dos refrescos",
                     "Una porción de pique macho",
                     "Dos almuerzos del día",
                     "Cinco salteñas y una Coca Cola"], id: \.self) { phrase in
                Button { simulateVoice(phrase) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "mic.circle").foregroundColor(TinkaColor.magenta)
                        Text(phrase).font(.tinka(13)).foregroundColor(TinkaColor.darkNavy)
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(TinkaColor.subtleText)
                    }
                    .padding(12).background(Color.white.opacity(0.7)).clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(TinkaColor.cardStroke))
                }
            }
        }
    }

    // MARK: Success overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 60)).foregroundColor(TinkaColor.green)
                Text("¡Venta registrada!").font(.tinka(22, weight: .bold)).foregroundColor(.white)
                Text("Bs. \(parsedTotal, specifier: "%.2f") añadidos al resumen").font(.tinka(14)).foregroundColor(.white.opacity(0.8))
            }
            .padding(32).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .transition(.opacity).animation(.easeInOut, value: showSuccess)
    }

    // MARK: Logic
    private func handleMicTap() {
        if flowState == .idle { startListening() }
        else if flowState == .listening { speech.stopListening() }
    }

    private func startListening() {
        reset()
        Task {
            let granted = await speech.requestPermissions()
            guard granted else { return }
            flowState = .listening
            speech.startListening()
        }
    }

    private func finishListening() {
        flowState = .processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            parsedProducts = VoiceParser.parse(speech.transcript)
            flowState = .result
        }
    }

    private func simulateVoice(_ phrase: String) {
        reset()
        flowState = .listening
        // Animate char by char for demo
        var built = ""
        for (i, ch) in phrase.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) {
                built.append(ch)
                speech.transcript = built
                if built == phrase {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { finishListening() }
                }
            }
        }
    }

    private func confirmSale() {
        guard !parsedProducts.isEmpty else { return }
        state.addSale(SaleItem(date: Date(), products: parsedProducts, total: parsedTotal, channel: .voice))
        showSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSuccess = false; reset() }
    }

    private func reset() {
        flowState = .idle
        speech.transcript = ""
        parsedProducts = []
        pulseScale = 1.0
    }
}

// MARK: - Parser
enum VoiceParser {
    private static let numberWords: [(String, Int)] = [
        ("cero", 0), ("un ", 1), ("una ", 1), ("uno", 1),
        ("dos", 2), ("tres", 3), ("cuatro", 4), ("cinco", 5),
        ("seis", 6), ("siete", 7), ("ocho", 8), ("nueve", 9),
        ("diez", 10), ("once", 11), ("doce", 12)
    ]

    private static let productMap: [(keywords: [String], name: String)] = [
        (["salteña", "salteñas"], "Salteña"),
        (["refresco", "refrescos", "bebida", "bebidas"], "Refresco"),
        (["almuerzo", "almuerzos", "almuerzo del día"], "Almuerzo"),
        (["pique macho", "pique"], "Pique Macho"),
        (["coca cola", "coca", "cola"], "Coca Cola")
    ]

    static func parse(_ text: String) -> [SaleProduct] {
        let t = text.lowercased()
        // Split by "y" to handle separate product mentions with separate quantities
        let segments = t.components(separatedBy: " y ")
        var results: [SaleProduct] = []

        for segment in segments {
            for mapping in productMap {
                let found = mapping.keywords.contains { segment.contains($0) }
                guard found && !results.contains(where: { $0.name == mapping.name }) else { continue }
                let qty = detectNumber(in: segment) ?? detectNumber(in: t) ?? 1
                let price = ProductCatalog.prices[mapping.name] ?? 5
                results.append(SaleProduct(name: mapping.name, qty: qty, price: price))
            }
        }
        return results
    }

    private static func detectNumber(in text: String) -> Int? {
        // Try digit first
        let words = text.components(separatedBy: .whitespaces)
        for w in words { if let n = Int(w) { return n } }
        // Then word
        for (word, value) in numberWords { if text.contains(word) { return value } }
        return nil
    }
}

// MARK: - Waveform
struct WaveformView: View {
    @State private var animPhase: CGFloat = 0
    let bars = 24

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<bars, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient.tinkaPrimary)
                    .frame(width: 5, height: barHeight(i))
                    .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(Double(i)*0.04), value: animPhase)
            }
        }
        .frame(height: 60)
        .onAppear { animPhase = 1 }
    }

    private func barHeight(_ i: Int) -> CGFloat {
        guard animPhase > 0 else { return 4 }
        let base = sin(Double(i) * 0.5 + Double(animPhase) * 2) * 0.5 + 0.5
        return CGFloat(base) * 48 + 8
    }
}

#Preview { VoiceView().environmentObject(AppState.shared) }
