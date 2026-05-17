import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var ownerName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var businessName = ""
    @State private var businessType = "Comida"
    @State private var city = ""
    @State private var phone = ""
    @State private var isLoading = false
    @State private var errorMsg = ""

    private let businessTypes = ["Comida", "Bebidas", "Panadería", "Mercado", "Ropa",
                                  "Tecnología", "Servicio", "Transporte", "Otro"]

    var isValid: Bool {
        !ownerName.isEmpty && !email.isEmpty && password.count >= 6
        && password == confirmPassword && !businessName.isEmpty && !city.isEmpty
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color(hex: "0A0F1E"), Color(hex: "1A0F3E")],
                               startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 22) {
                        headerSection
                        personalSection
                        businessSection
                        if !errorMsg.isEmpty {
                            Text(errorMsg).font(.tinka(13)).foregroundColor(TinkaColor.red)
                                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 4)
                        }
                        registerButton
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 24).padding(.top, 16)
                }
            }
            .navigationTitle("Crear cuenta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }.foregroundColor(TinkaColor.royalPurple)
                }
            }
        }
    }

    // MARK: - Sections
    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("Bienvenida a Tinka 🎉")
                .font(.tinka(22, weight: .bold)).foregroundColor(.white)
            Text("Completa tu perfil para comenzar")
                .font(.tinka(14)).foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
    }

    private var personalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("INFORMACIÓN PERSONAL")
            regField("person.fill", "Nombre completo", $ownerName)
            regField("envelope.fill", "Correo electrónico", $email,
                     keyboard: .emailAddress, caps: .none)
            regField("lock.fill", "Contraseña (mín. 6 caracteres)", $password, isSecure: true)
            regField("lock.fill", "Confirmar contraseña", $confirmPassword, isSecure: true)
            if !confirmPassword.isEmpty && password != confirmPassword {
                Text("Las contraseñas no coinciden").font(.tinka(12)).foregroundColor(TinkaColor.red)
            }
            regField("phone.fill", "Teléfono (opcional)", $phone, keyboard: .phonePad)
        }
        .regCard()
    }

    private var businessSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("TU NEGOCIO")
            regField("storefront.fill", "Nombre del negocio", $businessName)
            regField("mappin.circle.fill", "Ciudad", $city)

            VStack(alignment: .leading, spacing: 8) {
                Text("Tipo de negocio").font(.tinka(13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(businessTypes, id: \.self) { t in
                            Button { withAnimation { businessType = t } } label: {
                                Text(t)
                                    .font(.tinka(13, weight: businessType == t ? .bold : .medium))
                                    .foregroundColor(businessType == t ? .white : .white.opacity(0.65))
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(businessType == t
                                        ? AnyShapeStyle(LinearGradient.tinkaPrimary)
                                        : AnyShapeStyle(Color.white.opacity(0.08)))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .regCard()
    }

    private var registerButton: some View {
        Button { doRegister() } label: {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Crear mi cuenta").font(.tinka(17, weight: .bold))
                    }
                    .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(isValid
                ? AnyShapeStyle(LinearGradient.tinkaPrimary)
                : AnyShapeStyle(Color.white.opacity(0.15)))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: isValid ? TinkaColor.magenta.opacity(0.4) : .clear, radius: 14, y: 6)
        }
        .disabled(!isValid || isLoading)
    }

    // MARK: - Helpers
    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.tinka(11, weight: .bold))
            .foregroundColor(.white.opacity(0.4)).tracking(1.5)
    }

    @ViewBuilder
    private func regField(_ icon: String, _ placeholder: String, _ binding: Binding<String>,
                           keyboard: UIKeyboardType = .default,
                           caps: TextInputAutocapitalization = .words,
                           isSecure: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(TinkaColor.royalPurple).frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: binding)
                    .font(.tinka(15)).foregroundColor(.white).autocorrectionDisabled()
            } else {
                TextField(placeholder, text: binding)
                    .font(.tinka(15)).foregroundColor(.white)
                    .keyboardType(keyboard).textInputAutocapitalization(caps)
                    .autocorrectionDisabled()
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.12)))
    }

    private func doRegister() {
        errorMsg = ""; isLoading = true
        let profile = SignUpProfile(ownerName: ownerName, businessName: businessName,
                                    businessType: businessType, city: city, phone: phone)
        Task {
            do {
                try await AuthService.shared.signUp(
                    email: email.lowercased().trimmingCharacters(in: .whitespaces),
                    password: password, profile: profile)
                await AppState.shared.loadFromSupabase()
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    errorMsg = "Error al registrar: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Card modifier
private extension View {
    func regCard() -> some View {
        self.padding(18)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1)))
    }
}

#Preview { RegisterView() }
