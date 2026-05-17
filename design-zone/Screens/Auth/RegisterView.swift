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
    @State private var successMsg = ""
    @State private var showLoginButton = false
    @State private var showResetButton = false
    @State private var isSendingReset = false
    @State private var cooldownRemaining = 0
    @State private var cooldownTask: Task<Void, Never>? = nil

    private let businessTypes = ["Comida", "Bebidas", "Panadería", "Mercado", "Ropa",
                                  "Tecnología", "Servicio", "Transporte", "Otro"]

    var isValid: Bool {
        !ownerName.isEmpty && !email.isEmpty && password.count >= 6
        && password == confirmPassword && !businessName.isEmpty && !city.isEmpty
    }

    private var canSubmit: Bool {
        isValid && !isLoading && cooldownRemaining == 0
    }

    var body: some View {
        NavigationView {
            ZStack {
                TinkaBackgroundView(style: .dark)
                ScrollView {
                    VStack(spacing: 22) {
                        headerSection
                        personalSection
                        businessSection
                        statusSection
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
            .onDisappear {
                cooldownTask?.cancel()
            }
        }
    }

    // MARK: - Sections
    private var headerSection: some View {
        VStack(spacing: 6) {
            TinkaBrandLogo(size: 46)
                .padding(.bottom, 4)
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
                     keyboard: .emailAddress, caps: .never)
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
                    HStack(spacing: 10) {
                        ProgressView().tint(.white)
                        Text("Creando cuenta...").font(.tinka(17, weight: .bold))
                    }
                    .foregroundColor(.white)
                } else if cooldownRemaining > 0 {
                    Text("Intentar de nuevo en \(cooldownRemaining)s")
                        .font(.tinka(17, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Crear mi cuenta").font(.tinka(17, weight: .bold))
                    }
                    .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(canSubmit
                ? AnyShapeStyle(LinearGradient.tinkaPrimary)
                : AnyShapeStyle(Color.white.opacity(0.15)))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: canSubmit ? TinkaColor.magenta.opacity(0.4) : .clear, radius: 14, y: 6)
        }
        .disabled(!canSubmit)
    }

    @ViewBuilder
    private var statusSection: some View {
        if !errorMsg.isEmpty || !successMsg.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                if !errorMsg.isEmpty {
                    Text(errorMsg)
                        .font(.tinka(13))
                        .foregroundColor(TinkaColor.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if !successMsg.isEmpty {
                    Text(successMsg)
                        .font(.tinka(13, weight: .semibold))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if showLoginButton {
                    HStack(spacing: 10) {
                        Button { dismiss() } label: {
                            Text("Ir a iniciar sesión")
                                .font(.tinka(13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(TinkaColor.royalPurple)
                                .clipShape(Capsule())
                        }
                        if showResetButton {
                            Button { sendResetFromRegister() } label: {
                                Text(isSendingReset ? "Enviando..." : "Recuperar contraseña")
                                    .font(.tinka(13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .disabled(isSendingReset || normalizedEmail.isEmpty)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
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
                SecureField(text: binding, prompt: Text(placeholder).foregroundColor(.white.opacity(0.58))) {
                    Text(placeholder)
                }
                    .font(.tinka(15)).foregroundColor(.white).autocorrectionDisabled()
            } else {
                TextField(text: binding, prompt: Text(placeholder).foregroundColor(.white.opacity(0.58))) {
                    Text(placeholder)
                }
                    .font(.tinka(15)).foregroundColor(.white)
                    .keyboardType(keyboard).textInputAutocapitalization(caps)
                    .autocorrectionDisabled()
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.22)))
    }

    private func doRegister() {
        guard canSubmit else { return }
        errorMsg = ""
        successMsg = ""
        showLoginButton = false
        showResetButton = false
        isLoading = true
        let profile = SignUpProfile(ownerName: ownerName, businessName: businessName,
                                    businessType: businessType, city: city, phone: phone)
        Task {
            do {
                let result = try await AuthService.shared.signUp(
                    email: email.lowercased().trimmingCharacters(in: .whitespaces),
                    password: password, profile: profile)
                switch result {
                case .signedIn:
                    await AppState.shared.loadFromSupabase()
                    await MainActor.run { dismiss() }
                case .needsEmailConfirmation:
                    await MainActor.run {
                        successMsg = "Cuenta creada. Revisa tu correo para confirmar la cuenta."
                        showLoginButton = true
                        isLoading = false
                    }
                }
            } catch AuthFlowError.emailRateLimited(let seconds) {
                await MainActor.run {
                    errorMsg = "Ya solicitaste un registro hace poco. Espera unos segundos e intenta nuevamente. Si ya usaste este correo, intenta iniciar sesión o recupera la contraseña."
                    showLoginButton = true
                    showResetButton = true
                    isLoading = false
                    startCooldown(seconds: seconds)
                }
            } catch AuthFlowError.accountAlreadyExists {
                await MainActor.run {
                    errorMsg = "Esta cuenta ya existe. Intenta iniciar sesión."
                    showLoginButton = true
                    showResetButton = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMsg = "No se pudo completar el registro. Intenta nuevamente."
                    isLoading = false
                }
            }
        }
    }

    private var normalizedEmail: String {
        email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sendResetFromRegister() {
        guard !normalizedEmail.isEmpty, !isSendingReset else { return }
        isSendingReset = true
        successMsg = ""
        Task {
            do {
                try await AuthService.shared.sendPasswordReset(email: normalizedEmail)
                await MainActor.run {
                    successMsg = "Te enviamos un enlace para recuperar la contraseña."
                    isSendingReset = false
                }
            } catch {
                await MainActor.run {
                    errorMsg = "No se pudo enviar el correo de recuperación. Espera unos segundos e intenta otra vez."
                    isSendingReset = false
                }
            }
        }
    }

    private func startCooldown(seconds: Int) {
        cooldownTask?.cancel()
        cooldownRemaining = max(seconds, 1)
        cooldownTask = Task {
            while !Task.isCancelled && cooldownRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    cooldownRemaining = max(cooldownRemaining - 1, 0)
                }
            }
        }
    }
}

// MARK: - Card modifier
private extension View {
    func regCard() -> some View {
        self.padding(18)
            .background(Color.white.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.18)))
    }
}

#Preview { RegisterView() }
