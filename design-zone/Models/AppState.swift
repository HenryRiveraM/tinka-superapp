import SwiftUI
import Combine

// MARK: - Models

struct SaleItem: Identifiable, Codable {
    let id: UUID
    let date: Date
    let products: [SaleProduct]
    let total: Double
    let channel: SaleChannel

    init(id: UUID = UUID(), date: Date, products: [SaleProduct], total: Double, channel: SaleChannel) {
        self.id = id; self.date = date; self.products = products; self.total = total; self.channel = channel
    }
}

struct SaleProduct: Identifiable, Codable {
    let id: UUID
    let name: String
    let qty: Int
    let price: Double
    var subtotal: Double { Double(qty) * price }

    init(id: UUID = UUID(), name: String, qty: Int, price: Double) {
        self.id = id; self.name = name; self.qty = qty; self.price = price
    }
}

enum SaleChannel: String, Codable {
    case manual, voice, quick
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date

    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date) {
        self.id = id; self.text = text; self.isUser = isUser; self.timestamp = timestamp
    }
}

// MARK: - AppState

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var sales: [SaleItem] = [] {
        didSet { persist() }
    }
    @Published var chatMessages: [ChatMessage] = [] {
        didSet { persistChat() }
    }

    init() {
        loadSales()
        loadChat()
        if sales.isEmpty { sales = SeedData.defaultSales }
    }

    // MARK: Computed

    var todaySales: Double {
        let cal = Calendar.current
        return sales.filter { cal.isDateInToday($0.date) }.reduce(0) { $0 + $1.total }
    }

    var weekSales: Double {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sales.filter { $0.date >= start }.reduce(0) { $0 + $1.total }
    }

    var todaySaleCount: Int {
        Calendar.current.isDateInToday(Date()) ? sales.filter { Calendar.current.isDateInToday($0.date) }.count : 0
    }

    var weekSaleCount: Int {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sales.filter { $0.date >= start }.count
    }

    var utilityEstimate: Double { weekSales * 0.35 }

    var averageTicket: Double {
        let week = sales.filter {
            let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return $0.date >= start
        }
        guard !week.isEmpty else { return 0 }
        return week.reduce(0) { $0 + $1.total } / Double(week.count)
    }

    var topProduct: String {
        var counts: [String: Int] = [:]
        for sale in sales {
            for p in sale.products { counts[p.name, default: 0] += p.qty }
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? "Salteña"
    }

    var financialStatus: String {
        if todaySales >= 300 { return "Saludable" }
        if todaySales >= 100 { return "Regular" }
        return "Riesgo"
    }

    var financialStatusColor: Color {
        if todaySales >= 300 { return TinkaColor.green }
        if todaySales >= 100 { return TinkaColor.yellow }
        return TinkaColor.red
    }

    var tinkaScore: Int {
        let salesScore = min(Int(weekSales / 50), 30)   // up to 30 pts
        let consistencyScore: Int = {
            let cal = Calendar.current
            var days = Set<Int>()
            for sale in sales {
                let day = cal.ordinality(of: .day, in: .era, for: sale.date) ?? 0
                days.insert(day)
            }
            return min(days.count * 3, 20)  // up to 20 pts
        }()
        let utilityScore = min(Int(utilityEstimate / 40), 15)  // up to 15 pts
        return min(40 + salesScore + consistencyScore + utilityScore, 100)
    }

    // MARK: Daily data for chart (last 7 days)
    var dailyTrend: [(day: String, value: Double)] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_BO")
        formatter.dateFormat = "E"
        return (0..<7).reversed().map { offset -> (String, Double) in
            let date = cal.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let dayLabel = String(formatter.string(from: date).prefix(2)).capitalized
            let total = sales.filter { cal.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.total }
            return (dayLabel, total)
        }
    }

    // MARK: Actions

    func addSale(_ sale: SaleItem) {
        withAnimation { sales.insert(sale, at: 0) }
    }

    // MARK: Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(sales) {
            UserDefaults.standard.set(data, forKey: "tinka_sales_v1")
        }
    }

    private func loadSales() {
        guard let data = UserDefaults.standard.data(forKey: "tinka_sales_v1"),
              let decoded = try? JSONDecoder().decode([SaleItem].self, from: data) else { return }
        sales = decoded
    }

    private func persistChat() {
        if let data = try? JSONEncoder().encode(chatMessages) {
            UserDefaults.standard.set(data, forKey: "tinka_chat_v1")
        }
    }

    private func loadChat() {
        guard let data = UserDefaults.standard.data(forKey: "tinka_chat_v1"),
              let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) else { return }
        chatMessages = decoded
    }
}

// MARK: - Catalog

enum ProductCatalog {
    static let prices: [String: Double] = [
        "Salteña": 5.0,
        "Refresco": 4.0,
        "Almuerzo": 15.0,
        "Pique Macho": 35.0,
        "Coca Cola": 12.0
    ]
}

// MARK: - Seed

enum SeedData {
    static var defaultSales: [SaleItem] {
        let cal = Calendar.current
        func ago(_ h: Int) -> Date { cal.date(byAdding: .hour, value: -h, to: Date()) ?? Date() }
        return [
            SaleItem(date: ago(1), products: [.init(name: "Salteña", qty: 5, price: 5), .init(name: "Refresco", qty: 3, price: 4)], total: 37, channel: .voice),
            SaleItem(date: ago(2), products: [.init(name: "Almuerzo", qty: 2, price: 15)], total: 30, channel: .manual),
            SaleItem(date: ago(3), products: [.init(name: "Pique Macho", qty: 1, price: 35), .init(name: "Refresco", qty: 2, price: 4)], total: 43, channel: .quick),
            SaleItem(date: ago(26), products: [.init(name: "Salteña", qty: 8, price: 5)], total: 40, channel: .manual),
            SaleItem(date: ago(27), products: [.init(name: "Almuerzo", qty: 3, price: 15)], total: 45, channel: .quick),
            SaleItem(date: ago(50), products: [.init(name: "Salteña", qty: 10, price: 5), .init(name: "Refresco", qty: 5, price: 4)], total: 70, channel: .voice)
        ]
    }
}
