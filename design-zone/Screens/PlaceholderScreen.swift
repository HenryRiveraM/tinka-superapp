import SwiftUI

struct PlaceholderScreen: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        ZStack {
            TinkaBackgroundView(style: .light)
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.tinkaPrimary)
                        .frame(width: 110, height: 110)
                        .shadow(color: TinkaColor.magenta.opacity(0.35), radius: 24, x: 0, y: 12)
                    Image(systemName: icon)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text(title)
                    .font(.tinka(28, weight: .bold))
                    .foregroundStyle(TinkaColor.darkNavy)
                Text(subtitle)
                    .font(.tinka(15, weight: .medium))
                    .foregroundStyle(TinkaColor.subtleText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Text("Próximamente")
                    .font(.tinka(12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(LinearGradient.tinkaPrimary))
                    .padding(.top, 8)
            }
            .padding(.bottom, 80)
        }
    }
}
