import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var state: AppState
    @State private var notificationsOn = true
    @State private var biometricOn = true
    @State private var showLogoutAlert = false

    var body: some View {
        ZStack {
            background
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    profileHeader
                    businessCard
                    statsRow
                    settingsSection
                    securitySection
                    supportSection
                    logoutButton
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, 18).padding(.top, 8)
            }
        }
        .alert("Cerrar sesión", isPresented: $showLogoutAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Cerrar sesión", role: .destructive) {}
        } message: { Text("¿Estás segura que deseas cerrar sesión?") }
    }

    private var background: some View {
        ZStack {
            LinearGradient.tinkaSoftBackground.ignoresSafeArea()
            Circle().fill(TinkaColor.magenta.opacity(0.12)).frame(width: 280).blur(radius: 80).offset(x: -120, y: -220)
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(LinearGradient.tinkaPrimary).frame(width: 88, height: 88)
                    .shadow(color: TinkaColor.magenta.opacity(0.35), radius: 16, y: 6)
                Text("M").font(.tinka(36, weight: .bold)).foregroundColor(.white)
                Circle().fill(TinkaColor.green).frame(width: 22, height: 22)
                    .overlay(Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white))
                    .offset(x: 30, y: 30)
            }
            VStack(spacing: 4) {
                Text("Doña María García").font(.tinka(22, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                Text("Emprendedora · Cochabamba, Bolivia").font(.tinka(13)).foregroundColor(TinkaColor.subtleText)
                HStack(spacing: 6) {
                    Image(systemName: "phone.fill").font(.system(size: 11)).foregroundColor(TinkaColor.deepBlue)
                    Text("+591 70 123 456").font(.tinka(13)).foregroundColor(TinkaColor.deepBlue)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var businessCard: some View {
        VStack(spacing: 0) {
            profileRow(icon: "storefront.fill", color: TinkaColor.deepBlue, label: "Negocio", value: "Salteñas Doña María")
            Divider().padding(.horizontal, 16)
            profileRow(icon: "fork.knife", color: TinkaColor.magenta, label: "Categoría", value: "Comida / Restaurante")
            Divider().padding(.horizontal, 16)
            profileRow(icon: "mappin.circle.fill", color: TinkaColor.royalPurple, label: "Ciudad", value: "Cochabamba")
            Divider().padding(.horizontal, 16)
            profileRow(icon: "calendar", color: TinkaColor.green, label: "Miembro desde", value: "Enero 2024")
        }
        .glassCard()
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(value: "\(state.tinkaScore)", label: "Tinka Score", color: TinkaColor.magenta)
            statTile(value: "Bs. \(Int(state.weekSales))", label: "Esta semana", color: TinkaColor.deepBlue)
            statTile(value: "\(state.sales.count)", label: "Ventas totales", color: TinkaColor.royalPurple)
        }
    }

    private func statTile(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.tinka(18, weight: .bold)).foregroundColor(color)
            Text(label).font(.tinka(10)).foregroundColor(TinkaColor.subtleText).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(14).glassCard(cornerRadius: 16)
    }

    private var settingsSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Configuración")
            toggleRow(icon: "bell.fill", color: TinkaColor.deepBlue, label: "Notificaciones push", binding: $notificationsOn)
            Divider().padding(.horizontal, 16)
            profileRow(icon: "globe", color: TinkaColor.royalPurple, label: "Idioma", value: "Español")
            Divider().padding(.horizontal, 16)
            profileRow(icon: "paintpalette.fill", color: TinkaColor.magenta, label: "Tema", value: "Claro")
        }
        .glassCard()
    }

    private var securitySection: some View {
        VStack(spacing: 0) {
            sectionHeader("Seguridad")
            toggleRow(icon: "faceid", color: TinkaColor.green, label: "Face ID / Touch ID", binding: $biometricOn)
            Divider().padding(.horizontal, 16)
            profileRow(icon: "lock.fill", color: TinkaColor.deepBlue, label: "Cambiar PIN", value: "••••")
            Divider().padding(.horizontal, 16)
            profileRow(icon: "shield.fill", color: TinkaColor.royalPurple, label: "Privacidad de datos", value: "Protegidos")
        }
        .glassCard()
    }

    private var supportSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Soporte")
            profileRow(icon: "questionmark.circle.fill", color: TinkaColor.deepBlue, label: "Centro de ayuda", value: "")
            Divider().padding(.horizontal, 16)
            profileRow(icon: "star.fill", color: TinkaColor.yellow, label: "Calificar la app", value: "")
            Divider().padding(.horizontal, 16)
            profileRow(icon: "info.circle.fill", color: TinkaColor.subtleText, label: "Versión", value: "1.0.0 Beta")
        }
        .glassCard()
    }

    private var logoutButton: some View {
        Button { showLogoutAlert = true } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right").font(.system(size: 16))
                Text("Cerrar sesión")
            }
            .font(.tinka(15, weight: .semibold)).foregroundColor(TinkaColor.red).frame(maxWidth: .infinity).padding(16)
            .background(TinkaColor.red.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(TinkaColor.red.opacity(0.2)))
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title).font(.tinka(11, weight: .semibold)).foregroundColor(TinkaColor.subtleText).textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16).padding(.vertical, 10)
    }

    private func profileRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.12)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            }
            Text(label).font(.tinka(14)).foregroundColor(TinkaColor.darkNavy)
            Spacer()
            if !value.isEmpty { Text(value).font(.tinka(13)).foregroundColor(TinkaColor.subtleText) }
            Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(TinkaColor.subtleText.opacity(0.5))
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private func toggleRow(icon: String, color: Color, label: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.12)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            }
            Text(label).font(.tinka(14)).foregroundColor(TinkaColor.darkNavy)
            Spacer()
            Toggle("", isOn: binding).tint(TinkaColor.deepBlue).labelsHidden()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

#Preview { ProfileView().environmentObject(AppState.shared) }
