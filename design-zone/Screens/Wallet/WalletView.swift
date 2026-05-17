import SwiftUI

struct WalletView: View {
    @EnvironmentObject var state: AppState
    @State private var showQR = false
    @State private var showTransfer = false
    @State private var selectedAction: WalletAction? = nil

    enum WalletAction { case receive, pay, transfer }

    var body: some View {
        ZStack {
            background
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    walletHeader
                    balanceCard
                    actionButtons
                    qrCard
                    transactionsList
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, 18).padding(.top, 8)
            }
        }
        .sheet(isPresented: $showQR) { QRReceiveSheet().environmentObject(state) }
        .sheet(isPresented: $showTransfer) { TransferSheet().environmentObject(state) }
    }

    private var background: some View {
        ZStack {
            LinearGradient.tinkaSoftBackground.ignoresSafeArea()
            Circle().fill(TinkaColor.deepBlue.opacity(0.15)).frame(width: 350).blur(radius: 90).offset(x: -150, y: -200)
            Circle().fill(TinkaColor.magenta.opacity(0.1)).frame(width: 250).blur(radius: 70).offset(x: 150, y: 100)
        }
    }

    private var walletHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Mi Billetera").font(.tinka(28, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                Text("Banco FIE · Cuenta Emprendedor").font(.tinka(13)).foregroundColor(TinkaColor.subtleText)
            }
            Spacer()
            Image(systemName: "bell.badge.fill").font(.system(size: 20)).foregroundColor(TinkaColor.deepBlue)
        }
    }

    private var balanceCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(LinearGradient.tinkaPrimary)
            Circle().fill(Color.white.opacity(0.08)).frame(width: 180).offset(x: 100, y: -60)
            Circle().fill(Color.white.opacity(0.06)).frame(width: 120).offset(x: -80, y: 60)
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Saldo disponible").font(.tinka(13)).foregroundColor(.white.opacity(0.8))
                        Text("Bs. \(state.walletBalance, specifier: "%.2f")").font(.tinka(38, weight: .bold)).foregroundColor(.white)
                    }
                    Spacer()
                    Image(systemName: "creditcard.fill").font(.system(size: 28)).foregroundColor(.white.opacity(0.3))
                }
                .padding(.bottom, 20)
                HStack {
                    Text("**** **** **** 4721").font(.tinka(13, weight: .medium)).foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("Doña María G.").font(.tinka(13)).foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(24)
        }
        .shadow(color: TinkaColor.royalPurple.opacity(0.35), radius: 20, y: 10)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            WalletActionButton(icon: "qrcode", label: "Recibir", color: TinkaColor.green) { showQR = true }
            WalletActionButton(icon: "arrow.up.circle.fill", label: "Pagar", color: TinkaColor.deepBlue) { showTransfer = true }
            WalletActionButton(icon: "arrow.left.arrow.right", label: "Transferir", color: TinkaColor.royalPurple) { showTransfer = true }
        }
    }

    private var qrCard: some View {
        Button { showQR = true } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(TinkaColor.deepBlue.opacity(0.1)).frame(width: 56, height: 56)
                    Image(systemName: "qrcode").font(.system(size: 24)).foregroundColor(TinkaColor.deepBlue)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Cobrar con QR").font(.tinka(15, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
                    Text("Muestra tu código QR para recibir pagos").font(.tinka(12)).foregroundColor(TinkaColor.subtleText)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(TinkaColor.subtleText)
            }
            .padding(16).glassCard(cornerRadius: 16)
        }
    }

    private var transactionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Movimientos recientes").font(.tinka(16, weight: .semibold)).foregroundColor(TinkaColor.darkNavy)
            ForEach(state.walletTransactions.prefix(8)) { tx in TransactionRow(tx: tx) }
        }
    }
}

struct WalletActionButton: View {
    let icon: String; let label: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(color.opacity(0.12)).frame(width: 52, height: 52)
                    Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
                }
                Text(label).font(.tinka(12, weight: .medium)).foregroundColor(TinkaColor.darkNavy)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16).glassCard(cornerRadius: 16)
        }
    }
}

struct TransactionRow: View {
    let tx: WalletTransaction
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(tx.isCredit ? TinkaColor.green.opacity(0.12) : TinkaColor.red.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: tx.icon).font(.system(size: 16)).foregroundColor(tx.isCredit ? TinkaColor.green : TinkaColor.red)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(tx.description).font(.tinka(14, weight: .medium)).foregroundColor(TinkaColor.darkNavy)
                Text(tx.date, style: .relative).font(.tinka(11)).foregroundColor(TinkaColor.subtleText)
            }
            Spacer()
            Text("\(tx.isCredit ? "+" : "-")Bs. \(tx.amount, specifier: "%.0f")")
                .font(.tinka(15, weight: .bold)).foregroundColor(tx.isCredit ? TinkaColor.green : TinkaColor.red)
        }
        .padding(12).glassCard(cornerRadius: 14)
    }
}

// MARK: - QR Sheet
struct QRReceiveSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            LinearGradient.tinkaSoftBackground.ignoresSafeArea()
            VStack(spacing: 28) {
                RoundedRectangle(cornerRadius: 3).fill(Color.gray.opacity(0.3)).frame(width: 36, height: 4).padding(.top, 16)
                Text("Cobrar con QR").font(.tinka(22, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                ZStack {
                    RoundedRectangle(cornerRadius: 24).fill(Color.white).frame(width: 240, height: 240)
                        .shadow(color: TinkaColor.royalPurple.opacity(0.15), radius: 20, y: 8)
                    VStack(spacing: 12) {
                        Image(systemName: "qrcode").font(.system(size: 130)).foregroundColor(TinkaColor.darkNavy)
                    }
                }
                VStack(spacing: 4) {
                    Text("Salteñas Doña María").font(.tinka(18, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                    Text("ID: TK-4721-BOL").font(.tinka(13)).foregroundColor(TinkaColor.subtleText)
                    HStack(spacing: 4) {
                        Circle().fill(TinkaColor.green).frame(width: 8, height: 8)
                        Text("Banco FIE · Activo").font(.tinka(12)).foregroundColor(TinkaColor.green)
                    }
                }
                Button("Cerrar") { dismiss() }
                    .font(.tinka(15, weight: .medium)).foregroundColor(TinkaColor.subtleText)
                    .padding(.bottom, 20)
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Transfer Sheet
struct TransferSheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    @State private var amount = ""
    @State private var recipient = ""
    @State private var showSuccess = false
    var body: some View {
        ZStack {
            LinearGradient.tinkaSoftBackground.ignoresSafeArea()
            VStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 3).fill(Color.gray.opacity(0.3)).frame(width: 36, height: 4).padding(.top, 16)
                Text("Transferir").font(.tinka(22, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                VStack(spacing: 16) {
                    inputField(label: "Destinatario / Número", text: $recipient, placeholder: "Ej. 70123456")
                    inputField(label: "Monto (Bs.)", text: $amount, placeholder: "0.00")
                }
                Button {
                    guard let amt = Double(amount), amt > 0 else { return }
                    state.walletBalance -= amt
                    state.walletTransactions.insert(WalletTransaction(date: Date(), description: "Transferencia a \(recipient.isEmpty ? "contacto" : recipient)", amount: amt, isCredit: false, icon: "arrow.up.circle.fill"), at: 0)
                    showSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                } label: {
                    Text("Transferir").font(.tinka(16, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).padding(16)
                        .background(LinearGradient.tinkaPrimary).clipShape(RoundedRectangle(cornerRadius: 16))
                }
                if showSuccess {
                    Label("¡Transferencia exitosa!", systemImage: "checkmark.circle.fill").foregroundColor(TinkaColor.green).font(.tinka(15, weight: .semibold))
                }
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
    private func inputField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.tinka(12, weight: .medium)).foregroundColor(TinkaColor.subtleText)
            TextField(placeholder, text: text).font(.tinka(16)).padding(14)
                .background(Color.white.opacity(0.8)).clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(TinkaColor.cardStroke))
        }
    }
}

#Preview { WalletView().environmentObject(AppState.shared) }
