import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isListening = false
    @Published var permissionDenied = false
    @Published var error: String? = nil

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let recognizer: SFSpeechRecognizer?

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "es-BO")) ??
                     SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
    }

    func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in cont.resume(returning: status) }
        }
        guard speechStatus == .authorized else {
            permissionDenied = true
            return false
        }
        let micStatus = await AVAudioApplication.requestRecordPermission()
        if !micStatus { permissionDenied = true }
        return micStatus
    }

    func startListening() {
        guard !isListening else { return }
        guard recognizer != nil else {
            self.error = "Reconocimiento de voz no disponible en este dispositivo."
            return
        }
        transcript = ""
        error = nil
        do {
            try startSession()
            isListening = true
        } catch {
            self.error = "No se pudo iniciar el micrófono: \(error.localizedDescription)"
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }

    private func startSession() throws {
        recognitionTask?.cancel()
        recognitionTask = nil

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                Task { @MainActor in self.transcript = result.bestTranscription.formattedString }
            }
            if error != nil || result?.isFinal == true {
                Task { @MainActor in self.stopListening() }
            }
        }
    }
}
