import SwiftUI

struct HomeHeaderView: View {
    var body: some View {
        HStack(spacing: 12) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                Text("Hola \(TinkaSampleData.userName) 👋")
                    .font(.tinka(18, weight: .bold))
                    .foregroundStyle(TinkaColor.darkNavy)
                Text(TinkaSampleData.business)
                    .font(.tinka(12, weight: .medium))
                    .foregroundStyle(TinkaColor.subtleText)
            }
            Spacer()
            iconButton(system: "bell.fill", badge: true)
            iconButton(system: "gearshape.fill", badge: false)
        }
        .padding(.top, 8)
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(LinearGradient.tinkaPrimary).frame(width: 46, height: 46)
            Text("M")
                .font(.tinka(20, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: TinkaColor.royalPurple.opacity(0.35), radius: 10, x: 0, y: 4)
    }

    private func iconButton(system: String, badge: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(TinkaColor.darkNavy)
                .frame(width: 42, height: 42)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1))
            if badge {
                Circle().fill(TinkaColor.magenta)
                    .frame(width: 9, height: 9)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .offset(x: -4, y: 4)
            }
        }
    }
}
