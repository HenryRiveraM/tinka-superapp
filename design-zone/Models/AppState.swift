import SwiftUI
import Combine

struct SaleItem: Identifiable {
    let id = UUID()
    let date: Date
    let products: [SaleProduct]
    let total: Double
    let channel: SaleChannel
}

struct SaleProduct: Identifiable {
    let id = UUID()
    let name: String
    let qty: Int
    let price: Double
    var subtotal: Double { Double(qty) * price }
}

enum SaleChannel {
    case manual, voice, quick
}

struct Expense: Identifiable {
    let id = UUID()
    let date: Date
    let description: String
    let amount: Double
    let category: String
}

struct WalletTransaction: Identifiable {
    let id = UUID()
    let date: Date
    let description: String
    let amount: Double
    let isCredit: Bool
    let icon: String
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
}

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var sales: [SaleItem] = SeedData.sales
    @Published var expenses: [Expense] = SeedData.expenses
    @Published var walletBalance: Double = 1240.50
    @Published var walletTransactions: [WalletTransaction] = SeedData.transactions
    @Published var chatMessages: [ChatMessage] = []

    var todaySales: Double {
        let cal = Calendar.current
        return sales
            .filter { cal.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.total }
    }

    var weekSales: Double {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sales.filter { $0.date >= start }.reduce(0) { $0 + $1.total }
    }

    var tinkaScore: Int {
        let base = 68
        let bonus = min(Int(weekSales / 100), 20)
        return min(base + bonus, 99)
    }

    func addSale(_ sale: SaleItem) {
        withAnimation { sales.insert(sale, at: 0) }
        walletBalance += sale.total
        walletTransactions.insert(
            WalletTransaction(date: sale.date, description: "Venta registrada", amount: sale.total, isCredit: true, icon: "arrow.down.circle.fill"),
            at: 0
        )
    }
}

// MARK: - Seed data
enum SeedData {
    static let products: [String: Double] = [
        "Salteña": 5.0,
        "Refresco": 4.0,
        "Almuerzo": 15.0,
        "Pique Macho": 35.0
    ]

    static let sales: [SaleItem] = {
        let now = Date()
        let cal = Calendar.current
        func hoursAgo(_ h: Int) -> Date { cal.date(byAdding: .hour, value: -h, to: now)! }

        return [
            SaleItem(date: hoursAgo(1), products: [.init(name: "Salteña", qty: 5, price: 5), .init(name: "Refresco", qty: 3, price: 4)], total: 37, channel: .voice),
            SaleItem(date: hoursAgo(2), products: [.init(name: "Almuerzo", qty: 2, price: 15)], total: 30, channel: .manual),
            SaleItem(date: hoursAgo(3), products: [.init(name: "Pique Macho", qty: 1, price: 35), .init(name: "Refresco", qty: 2, price: 4)], total: 43, channel: .quick),
            SaleItem(date: hoursAgo(26), products: [.init(name: "Salteña", qty: 8, price: 5)], total: 40, channel: .manual),
            SaleItem(date: hoursAgo(27), products: [.init(name: "Almuerzo", qty: 3, price: 15)], total: 45, channel: .quick),
            SaleItem(date: hoursAgo(50), products: [.init(name: "Salteña", qty: 10, price: 5), .init(name: "Refresco", qty: 5, price: 4)], total: 70, channel: .voice)
        ]
    }()

    static let expenses: [Expense] = [
        .init(date: Date().addingTimeInterval(-3600*2), description: "Harina y masa", amount: 45, category: "Insumos"),
        .init(date: Date().addingTimeInterval(-3600*5), description: "Gas cocina", amount: 28, category: "Servicios"),
        .init(date: Date().addingTimeInterval(-3600*28), description: "Aceite y condimentos", amount: 32, category: "Insumos")
    ]

    static let transactions: [WalletTransaction] = [
        .init(date: Date().addingTimeInterval(-3600*1), description: "Venta salteñas", amount: 37, isCredit: true, icon: "arrow.down.circle.fill"),
        .init(date: Date().addingTimeInterval(-3600*2), description: "Compra insumos", amount: 45, isCredit: false, icon: "arrow.up.circle.fill"),
        .init(date: Date().addingTimeInterval(-3600*4), description: "Transferencia recibida", amount: 200, isCredit: true, icon: "qrcode"),
        .init(date: Date().addingTimeInterval(-3600*26), description: "Pago proveedor", amount: 120, isCredit: false, icon: "arrow.up.circle.fill"),
        .init(date: Date().addingTimeInterval(-3600*48), description: "Venta almuerzo", amount: 45, isCredit: true, icon: "arrow.down.circle.fill")
    ]
}
