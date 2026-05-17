import Foundation

// MARK: - Gemini AI Service
// Uses Gemini 2.0 Flash via REST API

actor GeminiService {
    static let shared = GeminiService()
    private var apiKey: String = ""

    func setApiKey(_ key: String) { apiKey = key }

    func chat(userMessage: String, businessContext: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw GeminiError.noApiKey
        }

        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let systemPrompt = """
Eres Tinka IA, el copiloto financiero inteligente de Doña María, una micro-emprendedora boliviana. Eres amigable, directo, empático y usas datos reales del negocio.
Responde SIEMPRE en español boliviano, de forma concisa (máximo 4 párrafos cortos). Usa emojis relevantes al inicio de cada punto clave. Llama a la usuaria "Doña María" cuando sea natural.

\(businessContext)

Instrucciones:
- Responde basándote en los datos del contexto del negocio arriba
- Si te preguntan sobre productos o combos, usa los datos del catálogo
- Si no hay datos suficientes, da consejos prácticos
- Nunca inventes datos que no estén en el contexto
- Usa números concretos del contexto cuando sea relevante
"""

        let body: [String: Any] = [
            "contents": [
                ["role": "user", "parts": [["text": systemPrompt + "\n\nPregunta del usuario: " + userMessage]]]
            ],
            "generationConfig": [
                "temperature": 0.8,
                "maxOutputTokens": 512,
                "topP": 0.9
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.networkError
        }

        if httpResponse.statusCode == 400 {
            throw GeminiError.invalidApiKey
        }

        if httpResponse.statusCode != 200 {
            throw GeminiError.httpError(httpResponse.statusCode)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw GeminiError.parseError
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum GeminiError: LocalizedError {
    case noApiKey, invalidApiKey, networkError, parseError, httpError(Int)

    var errorDescription: String? {
        switch self {
        case .noApiKey:       return "API key no configurada"
        case .invalidApiKey:  return "API key inválida. Verifica tu clave de Gemini."
        case .networkError:   return "Error de conexión. Verifica tu internet."
        case .parseError:     return "Error al procesar la respuesta de Gemini."
        case .httpError(let code): return "Error HTTP \(code) de Gemini."
        }
    }
}
