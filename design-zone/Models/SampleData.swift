import SwiftUI

struct AIInsight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let tint: Color
    let actionTitle: String?
    let targetTab: TinkaTab?

    init(icon: String, title: String, tint: Color, actionTitle: String? = nil, targetTab: TinkaTab? = nil) {
        self.icon = icon
        self.title = title
        self.tint = tint
        self.actionTitle = actionTitle
        self.targetTab = targetTab
    }
}

struct SalesPoint: Identifiable {
    let id = UUID()
    let day: String
    let value: Double
}

enum TinkaSampleData {
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

}
