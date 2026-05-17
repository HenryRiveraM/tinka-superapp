import SwiftUI

struct HomeHeaderView: View {
    @EnvironmentObject var state: AppState
    @Binding var selectedTab: TinkaTab
    @State private var showNotifications = false
    @State private var showSettings = false

    var body: some View {
        HStack(spacing: 16) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                Text("Hola \(state.ownerDisplayName)")
                    .font(.tinka(23, weight: .bold))
                    .foregroundStyle(TinkaColor.darkNavy)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                HStack(spacing: 6) {
                    Text(state.businessDisplayName)
                        .font(.tinka(15, weight: .medium))
                        .foregroundStyle(TinkaColor.subtleText)
                }
            }
            Spacer()
            iconButton(system: "bell.fill", badge: hasNotifications) { showNotifications = true }
            iconButton(system: "gearshape.fill", badge: false) { showSettings = true }
        }
        .padding(.top, 8)
        .sheet(isPresented: $showNotifications) {
            NotificationCenterSheet(selectedTab: $selectedTab)
                .environmentObject(state)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSettings) {
            HomeSettingsSheet(selectedTab: $selectedTab)
                .environmentObject(state)
                .presentationDetents([.medium, .large])
        }
    }

    private var hasNotifications: Bool {
        state.catalogProducts.count < 4 || state.sales.isEmpty || state.tinkaScore < 70
    }

    private var avatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black)
                .frame(width: 92, height: 70)
                .shadow(color: Color.black.opacity(0.16), radius: 14, x: 0, y: 8)
                .shadow(color: TinkaColor.magenta.opacity(0.12), radius: 16, x: 0, y: 4)
            Image("BancoFieGlowLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 78, height: 54)
        }
        .accessibilityLabel("Banco Fie")
    }

    private func iconButton(system: String, badge: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
        .buttonStyle(.plain)
    }
}

struct NotificationCenterSheet: View {
    @EnvironmentObject var state: AppState
    @Binding var selectedTab: TinkaTab
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if notifications.isEmpty {
                        notificationRow(icon: "checkmark.circle.fill", tint: TinkaColor.green,
                                        title: "Todo al día",
                                        body: "Tu catálogo, ventas y score están listos.",
                                        tab: nil)
                    } else {
                        ForEach(notifications) { item in
                            notificationRow(icon: item.icon, tint: item.tint, title: item.title, body: item.body, tab: item.tab)
                        }
                    }
                }
                .padding(18)
            }
            .background(TinkaBackgroundView(style: .light))
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var notifications: [HomeNotification] {
        var items: [HomeNotification] = []
        if state.catalogProducts.count < 4 {
            items.append(.init(icon: "shippingbox.fill", tint: TinkaColor.deepBlue,
                               title: "Catálogo incompleto",
                               body: "Carga productos base o agrega tus productos reales para que voz e IA funcionen mejor.",
                               tab: .products))
        }
        if state.sales.isEmpty {
            items.append(.init(icon: "mic.fill", tint: TinkaColor.magenta,
                               title: "Registra tu primera venta",
                               body: "Usa el micrófono o la pantalla de ventas para activar analytics y reportes.",
                               tab: .voice))
        }
        if state.tinkaScore < 70 {
            items.append(.init(icon: "chart.line.uptrend.xyaxis", tint: TinkaColor.yellow,
                               title: "Score en crecimiento",
                               body: "Cada venta registrada sube tu score y mejora las recomendaciones de Tinka.",
                               tab: .reports))
        }
        return items
    }

    private func notificationRow(icon: String, tint: Color, title: String, body: String, tab: TinkaTab?) -> some View {
        Button {
            if let tab {
                selectedTab = tab
                dismiss()
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle().fill(tint.opacity(0.14)).frame(width: 42, height: 42)
                    Image(systemName: icon).foregroundColor(tint)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.tinka(15, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                    Text(body).font(.tinka(13)).foregroundColor(TinkaColor.subtleText).multilineTextAlignment(.leading)
                }
                Spacer()
                if tab != nil {
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundColor(TinkaColor.subtleText)
                }
            }
            .padding(14)
            .glassCard(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }
}

struct HomeSettingsSheet: View {
    @EnvironmentObject var state: AppState
    @Binding var selectedTab: TinkaTab
    @Environment(\.dismiss) private var dismiss
    @State private var isLoadingStarterCatalog = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                profileSummary
                settingsAction(title: "Editar perfil", icon: "person.crop.circle.fill", tint: TinkaColor.deepBlue, tab: .profile)
                settingsAction(title: "Abrir catálogo", icon: "tag.fill", tint: TinkaColor.royalPurple, tab: .products)
                settingsAction(title: "Ver reportes", icon: "doc.text.fill", tint: TinkaColor.green, tab: .reports)
                Button { Task { await loadStarterCatalog() } } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(TinkaColor.magenta.opacity(0.14)).frame(width: 40, height: 40)
                            if isLoadingStarterCatalog { ProgressView().tint(TinkaColor.magenta).scaleEffect(0.75) }
                            else { Image(systemName: "sparkles").foregroundColor(TinkaColor.magenta) }
                        }
                        Text("Cargar productos base")
                            .font(.tinka(15, weight: .bold))
                            .foregroundColor(TinkaColor.darkNavy)
                        Spacer()
                    }
                    .padding(14)
                    .glassCard(cornerRadius: 16)
                }
                .buttonStyle(.plain)
                .disabled(isLoadingStarterCatalog)
                Spacer()
            }
            .padding(18)
            .background(TinkaBackgroundView(style: .light))
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var profileSummary: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LinearGradient.tinkaPrimary)
                .frame(width: 50, height: 50)
                .overlay(Text(String(state.ownerDisplayName.prefix(1)).uppercased()).font(.tinka(20, weight: .bold)).foregroundColor(.white))
            VStack(alignment: .leading, spacing: 4) {
                Text(state.ownerDisplayName).font(.tinka(17, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                Text(state.businessDisplayName).font(.tinka(13)).foregroundColor(TinkaColor.subtleText)
            }
            Spacer()
        }
        .padding(16)
        .glassCard(cornerRadius: 18)
    }

    private func settingsAction(title: String, icon: String, tint: Color, tab: TinkaTab) -> some View {
        Button {
            selectedTab = tab
            dismiss()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(tint.opacity(0.14)).frame(width: 40, height: 40)
                    Image(systemName: icon).foregroundColor(tint)
                }
                Text(title).font(.tinka(15, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundColor(TinkaColor.subtleText)
            }
            .padding(14)
            .glassCard(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func loadStarterCatalog() async {
        isLoadingStarterCatalog = true
        do {
            try await AuthService.shared.seedStarterCatalogForCurrentUser()
            await state.loadFromSupabase()
        } catch {
            NSLog("[Settings] Starter catalog seed failed: \(error.localizedDescription)")
        }
        isLoadingStarterCatalog = false
    }
}

private struct HomeNotification: Identifiable {
    let id = UUID()
    let icon: String
    let tint: Color
    let title: String
    let body: String
    let tab: TinkaTab?
}
