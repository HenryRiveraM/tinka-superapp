import SwiftUI

struct MicrocreditView: View {
    @EnvironmentObject var state: AppState
    @State private var loanAmount: Double = 5000
    @State private var months: Double = 12
    @State private var showApply = false
    @State private var applied = false

    private let annualRate = 0.18
    var monthlyPayment: Double {
        let r = annualRate / 12
        let n = months
        guard r > 0 else { return loanAmount / n }
        return loanAmount * r * pow(1 + r, n) / (pow(1 + r, n) - 1)
    }
    var totalPayment: Double { monthlyPayment * months }
    var totalInterest: Double { totalPayment - loanAmount }

    var body: some View {
        ZStack {
            background
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    creditHeader
                    eligibilityCard
                    simulatorCard
                    summaryCard
                    recommendationCard
                    applyButton
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, 18).padding(.top, 8)
            }
        }
        .sheet(isPresented: $showApply) { ApplySheet(applied: $applied).environmentObject(state) }
    }

    private var background: some View {
        ZStack {
            LinearGradient.tinkaSoftBackground.ignoresSafeArea()
            Circle().fill(TinkaColor.royalPurple.opacity(0.15)).frame(width: 300).blur(radius: 80).offset(x: 150, y: -250)
        }
    }

    private var creditHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Microcrédito").font(.tinka(28, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                Text("Banco FIE · Emprendedor Boliviano").font(.tinka(13)).foregroundColor(TinkaColor.subtleText)
            }
            Spacer()
            Image(systemName: "building.columns.fill").font(.system(size: 22)).foregroundColor(TinkaColor.deepBlue)
        }
    }

    private var eligibilityCard: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous).fill(LinearGradient.tinkaPrimary)
                Circle().fill(Color.white.opacity(0.07)).frame(width: 160).offset(x: 100, y: -50)
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Apta para microcrédito", systemImage: "checkmark.seal.fill")
                                .font(.tinka(13, weight: .semibold)).foregroundColor(.white)
                            Text("Salteñas Doña María").font(.tinka(20, weight: .bold)).foregroundColor(.white)
                        }
                        Spacer()
                        ZStack {
                            Circle().stroke(Color.white.opacity(0.3), lineWidth: 3).frame(width: 60, height: 60)
                            Text("\(state.tinkaScore)").font(.tinka(22, weight: .bold)).foregroundColor(.white)
                        }
                    }
                    HStack(spacing: 16) {
                        eligibilityStat(label: "Score", value: "\(state.tinkaScore)/100", icon: "star.fill")
                        eligibilityStat(label: "Ventas/día", value: "Bs. \(Int(state.weekSales/7))", icon: "chart.bar.fill")
                        eligibilityStat(label: "Capacidad", value: "Bs. 15.000", icon: "arrow.up.circle.fill")
                    }
                }
                .padding(22)
            }
            .shadow(color: TinkaColor.royalPurple.opacity(0.3), radius: 20, y: 10)
        }
    }

    private func eligibilityStat(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
            Text(value).font(.tinka(13, weight: .bold)).foregroundColor(.white)
            Text(label).font(.tinka(10)).foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    private var simulatorCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Simulador de Crédito").font(.tinka(16, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Monto").font(.tinka(13, weight: .medium)).foregroundColor(TinkaColor.subtleText)
                    Spacer()
                    Text("Bs. \(Int(loanAmount))").font(.tinka(15, weight: .bold)).foregroundColor(TinkaColor.deepBlue)
                }
                Slider(value: $loanAmount, in: 1000...15000, step: 500)
                    .tint(TinkaColor.deepBlue).animation(.spring(response: 0.3), value: loanAmount)
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Plazo").font(.tinka(13, weight: .medium)).foregroundColor(TinkaColor.subtleText)
                    Spacer()
                    Text("\(Int(months)) meses").font(.tinka(15, weight: .bold)).foregroundColor(TinkaColor.royalPurple)
                }
                Slider(value: $months, in: 3...36, step: 3)
                    .tint(TinkaColor.royalPurple).animation(.spring(response: 0.3), value: months)
            }
        }
        .padding(18).glassCard()
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                summaryItem(label: "Cuota mensual", value: "Bs. \(Int(monthlyPayment))", color: TinkaColor.magenta, icon: "calendar.badge.clock")
                summaryItem(label: "Total a pagar", value: "Bs. \(Int(totalPayment))", color: TinkaColor.deepBlue, icon: "bolivianosign.circle.fill")
            }
            HStack(spacing: 12) {
                summaryItem(label: "Intereses", value: "Bs. \(Int(totalInterest))", color: TinkaColor.royalPurple, icon: "percent")
                summaryItem(label: "Tasa anual", value: "18%", color: TinkaColor.green, icon: "chart.line.uptrend.xyaxis")
            }
        }
    }

    private func summaryItem(label: String, value: String, color: Color, icon: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.tinka(11)).foregroundColor(TinkaColor.subtleText)
                Text(value).font(.tinka(16, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
            }
            Spacer()
        }
        .padding(14).frame(maxWidth: .infinity).glassCard(cornerRadius: 16)
    }

    private var recommendationCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles").font(.system(size: 22)).foregroundColor(TinkaColor.magenta)
            VStack(alignment: .leading, spacing: 4) {
                Text("Recomendación Tinka IA").font(.tinka(13, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                Text("Con tus ventas de Bs. \(Int(state.weekSales/7))/día, puedes asumir una cuota de hasta Bs. \(Int(state.weekSales/7 * 0.25)) sin afectar tu flujo de caja.")
                    .font(.tinka(12)).foregroundColor(TinkaColor.subtleText).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16).glassCard(cornerRadius: 16)
    }

    private var applyButton: some View {
        Button { showApply = true } label: {
            HStack {
                Image(systemName: applied ? "checkmark.circle.fill" : "doc.text.fill")
                Text(applied ? "Solicitud enviada" : "Solicitar Preevaluación")
            }
            .font(.tinka(16, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).padding(18)
            .background(applied ? LinearGradient(colors: [TinkaColor.green], startPoint: .leading, endPoint: .trailing) : LinearGradient.tinkaPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: TinkaColor.magenta.opacity(0.3), radius: 12, y: 6)
        }
        .disabled(applied)
    }
}

struct ApplySheet: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) var dismiss
    @Binding var applied: Bool
    @State private var step = 0

    var body: some View {
        ZStack {
            LinearGradient.tinkaSoftBackground.ignoresSafeArea()
            VStack(spacing: 28) {
                RoundedRectangle(cornerRadius: 3).fill(Color.gray.opacity(0.3)).frame(width: 36, height: 4).padding(.top, 16)
                if step == 0 { preEvalStep } else { successStep }
            }
            .padding(.horizontal, 24)
        }
    }

    private var preEvalStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass").font(.system(size: 52)).foregroundColor(TinkaColor.deepBlue)
            Text("Preevaluación Banco FIE").font(.tinka(22, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
            Text("Evaluaremos tu perfil en base a:\n• Tinka Score: \(state.tinkaScore)/100\n• Ventas promedio semanales\n• Historial de movimientos\n• Sin costo ni compromiso")
                .font(.tinka(14)).foregroundColor(TinkaColor.subtleText).multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading)
                .padding(16).glassCard()
            Button { withAnimation { step = 1; applied = true } } label: {
                Text("Confirmar solicitud").font(.tinka(16, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).padding(16)
                    .background(LinearGradient.tinkaPrimary).clipShape(RoundedRectangle(cornerRadius: 16))
            }
            Button("Cancelar") { dismiss() }.font(.tinka(14)).foregroundColor(TinkaColor.subtleText)
            Spacer()
        }
    }

    private var successStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 72)).foregroundColor(TinkaColor.green)
            Text("¡Solicitud enviada!").font(.tinka(26, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
            Text("Un asesor de Banco FIE se contactará contigo en 24-48 horas. Tu número de referencia es TK-\(Int.random(in: 10000...99999)).")
                .font(.tinka(14)).foregroundColor(TinkaColor.subtleText).multilineTextAlignment(.center)
            Button("Cerrar") { dismiss() }.font(.tinka(16, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).padding(16)
                .background(LinearGradient.tinkaPrimary).clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer()
        }
        .padding(.top, 20)
    }
}

#Preview { MicrocreditView().environmentObject(AppState.shared) }
