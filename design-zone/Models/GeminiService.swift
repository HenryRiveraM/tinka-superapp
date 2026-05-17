import Foundation

// MARK: - Tinka AI Service (Secure Supabase Proxy)

actor GeminiService {
    static let shared = GeminiService()

    private let endpointURL = URL(string: "https://jhsnshxuxlnwkkbszcjx.supabase.co/functions/v1/tinka-ai")!
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impoc25zaHh1eGxud2trYnN6Y2p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5ODY3OTcsImV4cCI6MjA5NDU2Mjc5N30.ZAnGMYebwuKUBPu_lW13h9cQH4J59Uc91uyQBHAFU_0"

    func chat(userMessage: String, businessContext: String) async throws -> String {
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let body: [String: String] = [
            "message": userMessage,
            "context": businessContext
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw TinkaAIError.networkError
        }

        guard http.statusCode == 200 else {
            throw TinkaAIError.httpError(http.statusCode)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let reply = json["reply"] as? String, !reply.isEmpty else {
            throw TinkaAIError.parseError
        }

        return reply
    }
}

enum TinkaAIError: LocalizedError {
    case networkError, parseError, httpError(Int)

    var errorDescription: String? {
        switch self {
        case .networkError:        return "Sin conexión a internet. Revisa tu red."
        case .parseError:          return "Error al procesar la respuesta."
        case .httpError(let code): return "Error \(code) del servidor."
        }
    }
}
