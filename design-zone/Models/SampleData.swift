import SwiftUI

struct AIInsight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let tint: Color
}

struct QuickAction: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let gradient: [Color]
}

struct SalesPoint: Identifiable {
    let id = UUID()
    let day: String
    let value: Double
}

enum TinkaSampleData {
    static let userName = "Doña María"
    static let business = "Salteñas Doña María"

    static let todaySales: Double = 480
    static let weekRevenue: Double = 3120
    static let profit: Double = 1240
    static let tinkaScore: Int = 82

    static let trend: [SalesPoint] = [
        .init(day: "L", value: 320),
        .init(day: "M", value: 410),
        .init(day: "X", value: 380),
        .init(day: "J", value: 520),
        .init(day: "V", value: 690),
        .init(day: "S", value: 480),
        .init(day: "D", value: 320)
    ]

    static let insights: [AIInsight] = [
        .init(icon: "chart.line.uptrend.xyaxis", title: "Los viernes vendes 42% más refrescos", tint: TinkaColor.magenta),
        .init(icon: "exclamationmark.triangle.fill", title: "Tus gastos aumentaron 18% esta semana", tint: TinkaColor.yellow),
        .init(icon: "sparkles", title: "Tus salteñas generan mejor margen (62%)", tint: TinkaColor.green)
    ]

    static let quickActions: [QuickAction] = [
        .init(icon: "mic.fill", title: "Registrar\npor voz", gradient: [TinkaColor.magenta, TinkaColor.royalPurple]),
        .init(icon: "plus.circle.fill", title: "Nueva\nventa", gradient: [TinkaColor.deepBlue, TinkaColor.royalPurple]),
        .init(icon: "minus.circle.fill", title: "Registrar\ngasto", gradient: [Color(hex: "0EA5E9"), TinkaColor.deepBlue]),
        .init(icon: "sparkle", title: "Chat con\nTinka IA", gradient: [TinkaColor.royalPurple, TinkaColor.magenta])
    ]
}
