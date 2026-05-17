import SwiftUI

struct TinkaScoreCard: View {
    @EnvironmentObject var state: AppState
    let animate: Bool

    private var score: Int { state.tinkaScore }
    private var progress: Double { animate ? Double(score) / 100.0 : 0 }

    var body: some View {
        HStack(spacing: 18) {
            scoreRing
            VStack(alignment: .leading, spacing: 8) {
                Text("TINKA SCORE")
                    .font(.tinka(10, weight: .bold))
                    .foregroundStyle(TinkaColor.magenta)
                    .tracking(1.5)
                Text("Tu negocio va\nexcelente")
                    .font(.tinka(18, weight: .bold))
                    .foregroundStyle(TinkaColor.darkNavy)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("Apto para microcrédito")
                        .font(.tinka(11, weight: .semibold))
                }
                .foregroundStyle(TinkaColor.green)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(TinkaColor.green.opacity(0.12)))
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .glassCard()
    }

    private var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(TinkaColor.lightGray, lineWidth: 12)
                .frame(width: 110, height: 110)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(LinearGradient.tinkaPrimary,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 110, height: 110)
                .animation(.easeOut(duration: 1.4), value: progress)
            VStack(spacing: -2) {
                Text("\(score)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(TinkaColor.darkNavy)
                Text("/ 100")
                    .font(.tinka(10, weight: .semibold))
                    .foregroundStyle(TinkaColor.subtleText)
            }
        }
    }
}
