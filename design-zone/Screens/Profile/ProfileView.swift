import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var state: AppState
    @ObservedObject private var auth = AuthService.shared
    @State private var profile: DBBusinessProfile? = nil
    @State private var showEditSheet = false
    @State private var showLogoutAlert = false

    var ownerInitial: String {
        let name = profile?.ownerName ?? auth.userEmail ?? "?"
        return String(name.prefix(1)).uppercased()
    }

    var body: some View {
        ZStack {
            background
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    profileHeader
                    businessCard
                    statsRow
                    accountSection
                    logoutButton
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, 18).padding(.top, 8)
            }
        }
        .task { await loadProfile() }
        .sheet(isPresented: $showEditSheet, onDismiss: { Task { await loadProfile() } }) {
            EditProfileSheet(profile: $profile)
        }
        .alert("Cerrar sesión", isPresented: $showLogoutAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Cerrar sesión", role: .destructive) { doSignOut() }
        } message: { Text("¿Estás segura que deseas cerrar sesión?") }
    }

    private var background: some View {
        TinkaBackgroundView(style: .light)
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(LinearGradient.tinkaPrimary).frame(width: 88, height: 88)
                    .shadow(color: TinkaColor.magenta.opacity(0.35), radius: 16, y: 6)
                Text(ownerInitial).font(.tinka(36, weight: .bold)).foregroundColor(.white)
                Circle().fill(TinkaColor.green).frame(width: 22, height: 22)
                    .overlay(Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white))
                    .offset(x: 30, y: 30)
            }
            VStack(spacing: 4) {
                Text(profile?.ownerName ?? auth.userEmail ?? "—")
                    .font(.tinka(22, weight: .bold)).foregroundColor(TinkaColor.darkNavy)
                Text(auth.userEmail ?? "").font(.tinka(13)).foregroundColor(TinkaColor.subtleText)
                if let city = profile?.city, !city.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill").font(.system(size: 12)).foregroundColor(TinkaColor.deepBlue)
                        Text(city).font(.tinka(13)).foregroundColor(TinkaColor.deepBlue)
                    }
                }
            }
            Button { showEditSheet = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil").font(.system(size: 13))
                    Text("Editar perfil").font(.tinka(13, weight: .semibold))
                }
                .foregroundColor(TinkaColor.deepBlue)
                .padding(.horizontal, 18).padding(.vertical, 8)
                .background(TinkaColor.deepBlue.opacity(0.1))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(TinkaColor.deepBlue.opacity(0.25)))
            }
        }
        .padding(.vertical, 8)
    }

    private var businessCard: some View {
        VStack(spacing: 0) {
            infoRow("storefront.fill", TinkaColor.deepBlue, "Negocio",
                    profile?.businessName.isEmpty == false ? profile!.businessName : "—")
            Divider().padding(.horizontal, 16)
            infoRow("tag.fill", TinkaColor.magenta, "Tipo",
                    profile?.businessType.isEmpty == false ? profile!.businessType : "—")
            Divider().padding(.horizontal, 16)
            infoRow("mappin.circle.fill", TinkaColor.royalPurple, "Ciudad",
                    profile?.city.isEmpty == false ? profile!.city : "—")
            if let phone = profile?.phone, !phone.isEmpty {
                Divider().padding(.horizontal, 16)
                infoRow("phone.fill", TinkaColor.green, "Teléfono", phone)
            }
        }
        .glassCard()
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile("\(state.tinkaScore)", "Tinka Score", TinkaColor.magenta)
            statTile("Bs. \(Int(state.weekSales))", "Esta semana", TinkaColor.deepBlue)
            statTile("\(state.sales.count)", "Ventas totales", TinkaColor.royalPurple)
        }
    }

    private func statTile(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.tinka(18, weight: .bold)).foregroundColor(color)
            Text(label).font(.tinka(10)).foregroundColor(TinkaColor.subtleText).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(14).glassCard(cornerRadius: 16)
    }

    private var accountSection: some View {
        VStack(spacing: 0) {
            Text("Cuenta").font(.tinka(11, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
                .textCase(.uppercase).frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16).padding(.vertical, 10)
            infoRow("envelope.fill", TinkaColor.deepBlue, "Correo", auth.userEmail ?? "—", chevron: false)
            Divider().padding(.horizontal, 16)
            infoRow("shield.fill", TinkaColor.royalPurple, "Seguridad", "Datos protegidos con RLS", chevron: false)
            Divider().padding(.horizontal, 16)
            infoRow("info.circle.fill", TinkaColor.subtleText, "Versión", "1.0.0", chevron: false)
        }
        .glassCard()
    }

    private var logoutButton: some View {
        Button { showLogoutAlert = true } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right").font(.system(size: 16))
                Text("Cerrar sesión")
            }
            .font(.tinka(15, weight: .semibold)).foregroundColor(TinkaColor.red)
            .frame(maxWidth: .infinity).padding(16)
            .background(TinkaColor.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(TinkaColor.red.opacity(0.2)))
        }
    }

    private func infoRow(_ icon: String, _ color: Color, _ label: String,
                          _ value: String, chevron: Bool = true) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.12)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            }
            Text(label).font(.tinka(14)).foregroundColor(TinkaColor.darkNavy)
            Spacer()
            Text(value).font(.tinka(13)).foregroundColor(TinkaColor.subtleText).lineLimit(1)
            if chevron {
                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(TinkaColor.subtleText.opacity(0.5))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private func loadProfile() async {
        profile = try? await TinkaDataService.shared.fetchProfile()
        if let profile {
            AppState.shared.upsertLocalBusinessProfile(profile)
        } else {
            AppState.shared.businessProfile = nil
        }
    }

    private func doSignOut() {
        Task {
            await auth.signOut()
            AppState.shared.clearAll()
        }
    }
}

// MARK: - Edit Profile Sheet
struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var profile: DBBusinessProfile?
    @ObservedObject private var auth = AuthService.shared

    @State private var ownerName = ""
    @State private var businessName = ""
    @State private var businessType = "Comida"
    @State private var city = ""
    @State private var phone = ""
    @State private var isSaving = false
    @State private var errorMsg = ""

    private let businessTypes = ["Comida", "Bebidas", "Panadería", "Mercado",
                                  "Ropa", "Tecnología", "Servicio", "Transporte", "Otro"]

    var body: some View {
        NavigationView {
            ZStack {
                TinkaBackgroundView(style: .light)
                ScrollView {
                    VStack(spacing: 18) {
                        editField("Nombre completo", $ownerName)
                        editField("Nombre del negocio", $businessName)
                        editField("Ciudad", $city)
                        editField("Teléfono", $phone, keyboard: .phonePad)
                        businessTypeRow
                        if !errorMsg.isEmpty {
                            Text(errorMsg).font(.tinka(13)).foregroundColor(TinkaColor.red)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }.foregroundColor(TinkaColor.subtleText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Guardando..." : "Guardar") { save() }
                        .font(.tinka(15, weight: .bold))
                        .foregroundStyle(AnyShapeStyle(LinearGradient.tinkaPrimary))
                        .disabled(isSaving)
                }
            }
        }
        .onAppear { populateFields() }
    }

    private var businessTypeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tipo de negocio").font(.tinka(13, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(businessTypes, id: \.self) { t in
                        Button { businessType = t } label: {
                            Text(t)
                                .font(.tinka(13, weight: businessType == t ? .bold : .medium))
                                .foregroundColor(businessType == t ? .white : TinkaColor.darkNavy)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(businessType == t
                                    ? AnyShapeStyle(LinearGradient.tinkaPrimary)
                                    : AnyShapeStyle(Color.white.opacity(0.8)))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private func editField(_ label: String, _ binding: Binding<String>,
                            keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.tinka(13, weight: .semibold)).foregroundColor(TinkaColor.subtleText)
            TextField(label, text: binding)
                .font(.tinka(15)).foregroundColor(TinkaColor.darkNavy)
                .keyboardType(keyboard)
                .padding(14)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(TinkaColor.cardStroke))
        }
    }

    private func populateFields() {
        ownerName = profile?.ownerName ?? ""
        businessName = profile?.businessName ?? ""
        businessType = profile?.businessType.isEmpty == false ? profile!.businessType : "Comida"
        city = profile?.city ?? ""
        phone = profile?.phone ?? ""
    }

    private func save() {
        guard let uid = auth.userId else { return }
        isSaving = true; errorMsg = ""
        let updated = DBBusinessProfile(
            id: profile?.id ?? UUID().uuidString,
            userId: uid,
            ownerName: ownerName,
            businessName: businessName,
            businessType: businessType,
            city: city,
            phone: phone
        )
        Task {
            do {
                try await TinkaDataService.shared.upsertProfile(updated)
                await MainActor.run { profile = updated; isSaving = false; dismiss() }
            } catch {
                await MainActor.run { errorMsg = "Error al guardar."; isSaving = false }
            }
        }
    }
}

#Preview { ProfileView().environmentObject(AppState.shared) }
