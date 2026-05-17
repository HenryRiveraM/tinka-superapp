import SwiftUI
import Speech

// MARK: - Flow State
enum VoiceFlowState: Equatable {
    case idle, listening, processing, confirmed, ambiguous, success
}

// MARK: - Voice View
struct VoiceView: View {
    @EnvironmentObject var state: AppState
    @StateObject private var speech = SpeechRecognizer()

    @State private var flowState: VoiceFlowState = .idle
    @State private var parsedProducts: [SaleProduct] = []
    @State private var ambiguousCandidates: [ParsedMatch] = []
    @State private var showPermissionAlert = false

    var parsedTotal: Double { parsedProducts.reduce(0) { $0 + $1.subtotal } }

    var body: some View {
        ZStack {
            immersiveBackground
            VStack(spacing: 0) {
                voiceHeader
                Spacer()
                centerContent
                Spacer()
                bottomArea
                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 24)
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
            Text("Tinka necesita acceso al micrófono para registrar ventas por voz.")
        }
    }

    // MARK: - Background
    private var immersiveBackground: some View {
        ZStack {
            TinkaBackgroundView(style: .voice)
            LinearGradient(colors: [voiceAccent.opacity(0.22), .clear, voiceAccent.opacity(0.12)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.6), value: flowState)
        }
    }

    private var voiceAccent: Color {
        switch flowState {
        case .listening: return TinkaColor.magenta
        case .ambiguous: return TinkaColor.yellow
        case .confirmed: return TinkaColor.deepBlue
        case .success: return TinkaColor.green
        default: return TinkaColor.royalPurple
        }
    }

    // MARK: - Header
    private var voiceHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Registro por Voz")
                    .font(.tinka(22, weight: .bold)).foregroundColor(.white)
                Text(headerSubtitle)
                    .font(.tinka(13)).foregroundColor(.white.opacity(0.55))
                    .animation(.easeInOut(duration: 0.3), value: flowState)
            }
            Spacer()
            statusPill
        }
        .padding(.top, 16)
    }

    private var headerSubtitle: String {
        switch flowState {
        case .idle:       return "Di lo que vendiste"
        case .listening:  return "Escuchando…"
        case .processing: return "Analizando tu voz…"
        case .ambiguous:  return "¿Quisiste decir alguno de estos?"
        case .confirmed:  return "Tinka detectó esto"
        case .success:    return "¡Venta guardada!"
        }
    }

    private var statusPill: some View {
        let (label, color): (String, Color) = {
            switch flowState {
            case .idle:       return ("Listo", TinkaColor.subtleText)
            case .listening:  return ("● Escuchando", TinkaColor.magenta)
            case .processing: return ("Procesando", TinkaColor.yellow)
            case .ambiguous:  return ("? Confirmar", TinkaColor.yellow)
            case .confirmed:  return ("Detectado", TinkaColor.deepBlue)
            case .success:    return ("✓ Guardado", TinkaColor.green)
            }
        }()
        return Text(label)
            .font(.tinka(12, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.4)))
            .animation(.easeInOut(duration: 0.3), value: flowState)
    }

    // MARK: - Center content
    @ViewBuilder
    private var centerContent: some View {
        switch flowState {
        case .idle:       idleCenter
        case .listening:  listeningCenter
        case .processing: processingCenter
        case .ambiguous:  ambiguousCard
        case .confirmed:  confirmationCard
        case .success:    successCenter
        }
    }

    // MARK: - IDLE
    private var idleCenter: some View {
        VStack(spacing: 32) {
            pulseMicButton(isListening: false)
            VStack(spacing: 8) {
                Text("Toca para hablar").font(.tinka(20, weight: .bold)).foregroundColor(.white)
                Text("Tinka entiende tu catálogo actual").font(.tinka(14)).foregroundColor(.white.opacity(0.5))
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - LISTENING
    private var listeningCenter: some View {
        VStack(spacing: 28) {
            pulseMicButton(isListening: true)
            liveTranscriptBox
            LiveWaveformView()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - PROCESSING
    private var processingCenter: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle().fill(TinkaColor.royalPurple.opacity(0.15)).frame(width: 110, height: 110)
                Circle().stroke(LinearGradient.tinkaPrimary, lineWidth: 3).frame(width: 110, height: 110)
                Image(systemName: "sparkles")
                    .font(.system(size: 44)).foregroundColor(TinkaColor.magenta)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
            }
            VStack(spacing: 6) {
                Text("Analizando tu voz…").font(.tinka(18, weight: .bold)).foregroundColor(.white)
                Text("Identificando productos del catálogo")
                    .font(.tinka(13)).foregroundColor(.white.opacity(0.55))
            }
            ProgressView().tint(TinkaColor.magenta).scaleEffect(1.4)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - AMBIGUOUS ("Did you mean?")
    private var ambiguousCard: some View {
        VStack(spacing: 18) {
            // Transcript quote
            HStack(spacing: 10) {
                Image(systemName: "quote.bubble.fill").foregroundColor(TinkaColor.yellow.opacity(0.8))
                Text(speech.transcript.isEmpty ? "—" : "\"\(speech.transcript)\"")
                    .font(.tinka(14)).foregroundColor(.white.opacity(0.75)).italic().lineLimit(2)
                Spacer()
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(TinkaColor.yellow.opacity(0.25)))

            // Title
            HStack(spacing: 8) {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(TinkaColor.yellow).font(.system(size: 18))
                Text("No estoy segura, ¿quisiste decir?")
                    .font(.tinka(15, weight: .bold)).foregroundColor(.white)
            }

            // Candidate buttons
            VStack(spacing: 10) {
                ForEach(ambiguousCandidates.prefix(4), id: \.product.id) { match in
                    ambiguousButton(match: match)
                }
            }

            Text("O toca **Reintentar** para volver a hablar")
                .font(.tinka(12)).foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(TinkaColor.yellow.opacity(0.3)))
        .transition(.asymmetric(insertion: .scale(scale: 0.92).combined(with: .opacity), removal: .opacity))
    }

    private func ambiguousButton(match: ParsedMatch) -> some View {
        let qty = match.qty
        let prod = match.product
        return Button {
            withAnimation(.spring(response: 0.4)) {
                parsedProducts = [SaleProduct(name: prod.name, qty: qty, price: prod.price)]
                flowState = .confirmed
            }
        } label: {
            HStack(spacing: 14) {
                Text(prod.emoji).font(.system(size: 26))
                VStack(alignment: .leading, spacing: 2) {
                    Text(prod.name).font(.tinka(15, weight: .bold)).foregroundColor(.white)
                    Text("Bs. \(prod.price, specifier: "%.0f") c/u")
                        .font(.tinka(12)).foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("\(qty)×").font(.tinka(13, weight: .bold)).foregroundColor(TinkaColor.magenta)
                    Text("Bs. \(prod.price * Double(qty), specifier: "%.0f")")
                        .font(.tinka(13, weight: .bold)).foregroundColor(TinkaColor.deepBlue)
                }
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.white.opacity(0.3))
            }
            .padding(14)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(TinkaColor.yellow.opacity(0.2)))
        }
    }

    // MARK: - CONFIRMED
    private var confirmationCard: some View {
        VStack(spacing: 16) {
            transcriptQuote
            detectedProductsCard
            if parsedProducts.isEmpty { retryHint }
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.92).combined(with: .opacity),
            removal: .opacity)
        )
    }

    private var transcriptQuote: some View {
        HStack(spacing: 10) {
            Image(systemName: "quote.bubble.fill").foregroundColor(TinkaColor.royalPurple.opacity(0.8))
            Text(speech.transcript.isEmpty ? "—" : "\"\(speech.transcript)\"")
                .font(.tinka(14)).foregroundColor(.white.opacity(0.75)).italic().lineLimit(2)
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1)))
    }

    private var detectedProductsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: parsedProducts.isEmpty ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundColor(parsedProducts.isEmpty ? TinkaColor.red : TinkaColor.green)
                    .font(.system(size: 18))
                Text(parsedProducts.isEmpty ? "No detecté productos" : "Tinka detectó:")
                    .font(.tinka(16, weight: .bold)).foregroundColor(.white)
            }
            if !parsedProducts.isEmpty {
                ForEach(parsedProducts) { p in
                    productRow(p)
                }
                Divider().background(Color.white.opacity(0.15))
                HStack {
                    Text("TOTAL").font(.tinka(12, weight: .black))
                        .foregroundColor(.white.opacity(0.55)).tracking(1.2)
                    Spacer()
                    Text("Bs. \(parsedTotal, specifier: "%.2f")")
                        .font(.tinka(26, weight: .black)).foregroundColor(TinkaColor.magenta)
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
            .stroke(parsedProducts.isEmpty ? TinkaColor.red.opacity(0.4) : TinkaColor.green.opacity(0.4)))
    }

    private func productRow(_ p: SaleProduct) -> some View {
        HStack(spacing: 10) {
            Text("\(p.qty)×").font(.tinka(22, weight: .black)).foregroundColor(TinkaColor.magenta)
            VStack(alignment: .leading, spacing: 1) {
                Text(p.name).font(.tinka(16, weight: .semibold)).foregroundColor(.white)
                Text("Bs. \(p.price, specifier: "%.0f") c/u").font(.tinka(12)).foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Text("Bs. \(p.subtotal, specifier: "%.0f")")
                .font(.tinka(16, weight: .bold)).foregroundColor(TinkaColor.deepBlue)
        }
        .padding(12)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var retryHint: some View {
        VStack(spacing: 6) {
            Text("💡 Tip: Di algo como")
                .font(.tinka(12)).foregroundColor(.white.opacity(0.45))
            Text("\"Vendí dos salteñas y un refresco\"")
                .font(.tinka(13, weight: .semibold)).foregroundColor(.white.opacity(0.65)).italic()
        }
    }

    // MARK: - SUCCESS
    private var successCenter: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(TinkaColor.green.opacity(0.2)).frame(width: 130, height: 130)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72)).foregroundColor(TinkaColor.green)
            }
            .scaleEffect(flowState == .success ? 1 : 0.5)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: flowState)
            VStack(spacing: 6) {
                Text("¡Venta registrada!").font(.tinka(24, weight: .black)).foregroundColor(.white)
                Text("Bs. \(parsedTotal, specifier: "%.2f") añadidos a tu resumen")
                    .font(.tinka(15)).foregroundColor(.white.opacity(0.65))
            }
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .opacity)
        )
    }

    // MARK: - Live Transcript Box
    private var liveTranscriptBox: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.07))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.12)))
            if speech.transcript.isEmpty {
                Text("Habla ahora…")
                    .font(.tinka(16)).foregroundColor(.white.opacity(0.3)).italic()
            } else {
                Text(speech.transcript)
                    .font(.tinka(17, weight: .medium)).foregroundColor(.white)
                    .multilineTextAlignment(.center).padding(.horizontal, 16)
                    .animation(.easeIn(duration: 0.15), value: speech.transcript)
            }
        }
        .frame(minHeight: 72)
        .padding(.horizontal, 4)
    }

    // MARK: - Bottom Area
    @ViewBuilder
    private var bottomArea: some View {
        switch flowState {
        case .idle:       examplePhrases
        case .listening:  stopButton
        case .processing: Color.clear.frame(height: 60)
        case .ambiguous:  ambiguousBottomButtons
        case .confirmed:  confirmButtons
        case .success:    newSaleButton
        }
    }

    private var examplePhrases: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EJEMPLOS DE VOZ")
                .font(.tinka(11, weight: .bold))
                .foregroundColor(.white.opacity(0.35))
                .tracking(1.2)
            let examples = buildExamples()
            ForEach(examples, id: \.self) { phrase in
                Button { simulateVoice(phrase) } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "waveform").font(.system(size: 14)).foregroundColor(TinkaColor.magenta)
                        Text(phrase).font(.tinka(13)).foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Image(systemName: "play.fill").font(.system(size: 10)).foregroundColor(.white.opacity(0.3))
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1)))
                }
            }
        }
    }

    private func buildExamples() -> [String] {
        let active = state.catalogProducts.filter { $0.isActive }.prefix(3)
        if active.isEmpty {
            return ["Vendí tres salteñas y dos refrescos", "Vendí un combo almuerzo"]
        }
        var list: [String] = []
        let prods = Array(active)
        if prods.count >= 2 {
            list.append("Vendí dos \(pluralName(prods[0].name)) y un \(prods[1].name)")
        }
        if prods.count >= 1 {
            list.append("Una porción de \(prods[0].name)")
        }
        if let combo = state.combos.first(where: { $0.isActive }) {
            list.append("Vendí un \(combo.name)")
        } else if prods.count >= 3 {
            list.append("Tres \(pluralName(prods[2].name))")
        }
        return list
    }

    private func pluralName(_ name: String) -> String {
        name.lowercased().hasSuffix("s") ? name : "\(name)s"
    }

    private var stopButton: some View {
        Button { speech.stopListening() } label: {
            HStack(spacing: 10) {
                Image(systemName: "stop.fill").font(.system(size: 16))
                Text("Detener y analizar").font(.tinka(16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity).padding(18)
            .background(TinkaColor.magenta.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(TinkaColor.magenta.opacity(0.5)))
        }
    }

    private var ambiguousBottomButtons: some View {
        HStack(spacing: 12) {
            Button { reset() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark").font(.system(size: 13))
                    Text("Cancelar").font(.tinka(15, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.65))
                .frame(maxWidth: .infinity).padding(16)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12)))
            }
            Button { startListening() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mic.fill").font(.system(size: 13))
                    Text("Reintentar").font(.tinka(15, weight: .medium))
                }
                .foregroundColor(TinkaColor.magenta)
                .frame(maxWidth: .infinity).padding(16)
                .background(TinkaColor.magenta.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(TinkaColor.magenta.opacity(0.35)))
            }
        }
    }

    private var confirmButtons: some View {
        VStack(spacing: 12) {
            Button { confirmSale() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 18))
                    Text("Confirmar venta").font(.tinka(17, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(18)
                .background(parsedProducts.isEmpty
                    ? AnyShapeStyle(Color.gray.opacity(0.3))
                    : AnyShapeStyle(LinearGradient.tinkaPrimary))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: parsedProducts.isEmpty ? .clear : TinkaColor.magenta.opacity(0.4), radius: 14, y: 6)
            }
            .disabled(parsedProducts.isEmpty)

            HStack(spacing: 12) {
                Button { reset() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark").font(.system(size: 13))
                        Text("Cancelar").font(.tinka(15, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.65))
                    .frame(maxWidth: .infinity).padding(16)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12)))
                }
                Button { startListening() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "mic.fill").font(.system(size: 13))
                        Text("Reintentar").font(.tinka(15, weight: .medium))
                    }
                    .foregroundColor(TinkaColor.magenta)
                    .frame(maxWidth: .infinity).padding(16)
                    .background(TinkaColor.magenta.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(TinkaColor.magenta.opacity(0.35)))
                }
            }
        }
    }

    private var newSaleButton: some View {
        Button { reset() } label: {
            HStack(spacing: 8) {
                Image(systemName: "mic.fill").font(.system(size: 16))
                Text("Nueva venta").font(.tinka(16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity).padding(18)
            .background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.25)))
        }
    }

    // MARK: - Mic Button
    private func pulseMicButton(isListening: Bool) -> some View {
        PulsingMicButton(isListening: isListening) { handleMicTap() }
    }

    // MARK: - Logic
    private func handleMicTap() {
        if flowState == .idle { startListening() }
        else if flowState == .listening { speech.stopListening() }
    }

    private func startListening() {
        reset()
        Task {
            let granted = await speech.requestPermissions()
            guard granted else { return }
            await MainActor.run { flowState = .listening }
            speech.startListening()
        }
    }

    private func finishListening() {
        guard flowState == .listening else { return }
        withAnimation { flowState = .processing }
        let captured = speech.transcript
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard flowState == .processing else { return }
            let result = VoiceParser.parse(captured)
            withAnimation(.spring(response: 0.45)) {
                if result.hasAmbiguity {
                    ambiguousCandidates = result.ambiguous
                    flowState = .ambiguous
                } else {
                    parsedProducts = result.confirmed
                    flowState = .confirmed
                }
            }
        }
    }

    private func simulateVoice(_ phrase: String) {
        reset()
        withAnimation { flowState = .listening }
        speech.transcript = ""
        var built = ""
        let chars = Array(phrase)
        let total = chars.count
        for (i, ch) in chars.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.03) {
                built.append(ch)
                speech.transcript = built
                if built.count == total {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        guard flowState == .listening else { return }
                        withAnimation { flowState = .processing }
                        let captured = speech.transcript
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            guard flowState == .processing else { return }
                            let result = VoiceParser.parse(captured)
                            withAnimation(.spring(response: 0.45)) {
                                if result.hasAmbiguity {
                                    ambiguousCandidates = result.ambiguous
                                    flowState = .ambiguous
                                } else {
                                    parsedProducts = result.confirmed
                                    flowState = .confirmed
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func confirmSale() {
        guard !parsedProducts.isEmpty else { return }
        let saleTotal = parsedTotal
        let saleProducts = parsedProducts
        state.addSale(SaleItem(date: Date(), products: saleProducts, total: saleTotal, channel: .voice))
        withAnimation(.spring(response: 0.5)) { flowState = .success }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { reset() }
        }
    }

    private func reset() {
        flowState = .idle
        speech.transcript = ""
        parsedProducts = []
        ambiguousCandidates = []
    }
}

// MARK: - Pulsing Mic Button
struct PulsingMicButton: View {
    let isListening: Bool
    let action: () -> Void
    @State private var pulse: CGFloat = 1.0

    var body: some View {
        Button(action: action) {
            ZStack {
                if isListening {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(TinkaColor.magenta.opacity(0.25 - Double(i) * 0.07), lineWidth: 1.5)
                            .frame(width: 100 + CGFloat(i) * 34, height: 100 + CGFloat(i) * 34)
                            .scaleEffect(pulse)
                            .animation(
                                .easeInOut(duration: 1.1)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.22),
                                value: pulse
                            )
                    }
                }
                Circle()
                    .fill(isListening
                        ? AnyShapeStyle(TinkaColor.magenta)
                        : AnyShapeStyle(LinearGradient.tinkaPrimary))
                    .frame(width: 96, height: 96)
                    .shadow(color: (isListening ? TinkaColor.magenta : TinkaColor.royalPurple).opacity(0.6),
                            radius: 26, y: 10)
                Image(systemName: isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 38, weight: .bold)).foregroundColor(.white)
            }
        }
        .frame(width: 180, height: 180)
        .onAppear { if isListening { pulse = 1.14 } }
        .onChange(of: isListening) { _, v in pulse = v ? 1.14 : 1.0 }
    }
}

// MARK: - Live Waveform
struct LiveWaveformView: View {
    @State private var heights: [CGFloat] = Array(repeating: 4, count: 24)
    @State private var timer: Timer? = nil

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<heights.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient.tinkaPrimary.opacity(0.85))
                    .frame(width: 5, height: heights[i])
                    .animation(.easeInOut(duration: 0.18), value: heights[i])
            }
        }
        .frame(height: 52)
        .onAppear { startAnimating() }
        .onDisappear { timer?.invalidate() }
    }

    private func startAnimating() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            for i in 0..<heights.count { heights[i] = CGFloat.random(in: 4...48) }
        }
    }
}

#Preview { VoiceView().environmentObject(AppState.shared) }
