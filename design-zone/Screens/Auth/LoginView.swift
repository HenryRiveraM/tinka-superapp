import SwiftUI

struct LoginView: View {
    @ObservedObject private var auth = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMsg = ""
    @State private var showRegister = false
    @State private var showReset = false

    var body: some View {
        ZStack {
            loginBackground
            ScrollView {
                VStack(spacing: 0) {
                    logoSection
                    formCard
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showRegister) { RegisterView() }
        .sheet(isPresented: $showReset) { ResetPasswordView() }
    }

    // MARK: - Background
    private var loginBackground: some View {
        TinkaBackgroundView(style: .dark)
    }

    // MARK: - Logo
    private var logoSection: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            TinkaBrandLogo(size: 84)
            VStack(spacing: 6) {
                Text("Tinka").font(.tinka(34, weight: .black)).foregroundColor(.white)
                Text("Tu asistente de negocios").font(.tinka(15)).foregroundColor(.white.opacity(0.55))
            }
            Spacer().frame(height: 36)
        }
    }

    // MARK: - Form card
    private var formCard: some View {
        VStack(spacing: 20) {
            Text("Iniciar sesión").font(.tinka(22, weight: .bold)).foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            authField(icon: "envelope.fill", placeholder: "Correo electrónico",
                      text: $email, keyboard: .emailAddress)
            authField(icon: "lock.fill", placeholder: "Contraseña",
                      text: $password, isSecure: true)

            if !errorMsg.isEmpty {
                Text(errorMsg).font(.tinka(13)).foregroundColor(TinkaColor.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }

            Button { doSignIn() } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Iniciar sesión").font(.tinka(17, weight: .bold)).foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(LinearGradient.tinkaPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: TinkaColor.magenta.opacity(0.4), radius: 14, y: 6)
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)

            Button { showReset = true } label: {
                Text("¿Olvidaste tu contraseña?")
                    .font(.tinka(14, weight: .semibold)).foregroundColor(.white.opacity(0.72))
            }

            Divider().background(Color.white.opacity(0.15)).padding(.vertical, 4)

            Button { showRegister = true } label: {
                HStack(spacing: 6) {
                    Text("¿No tienes cuenta?").font(.tinka(14)).foregroundColor(.white.opacity(0.6))
                    Text("Crear cuenta").font(.tinka(14, weight: .bold))
                        .foregroundStyle(AnyShapeStyle(LinearGradient.tinkaPrimary))
                }
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.075))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.18)))
    }

    // MARK: - Helpers
    @ViewBuilder
    private func authField(icon: String, placeholder: String,
                           text: Binding<String>, keyboard: UIKeyboardType = .default,
                           isSecure: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(TinkaColor.royalPurple)
                .frame(width: 20)
            if isSecure {
                SecureField(text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.58))) {
                    Text(placeholder)
                }
                    .font(.tinka(15)).foregroundColor(.white)
                    .autocorrectionDisabled()
            } else {
                TextField(text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.58))) {
                    Text(placeholder)
                }
                    .font(.tinka(15)).foregroundColor(.white)
                    .keyboardType(keyboard)
                    .textContentType(keyboard == .emailAddress ? .emailAddress : .none)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.22)))
    }

    private func doSignIn() {
        guard !email.isEmpty, !password.isEmpty else { return }
        isLoading = true; errorMsg = ""
        Task {
            do {
                try await auth.signIn(email: email.lowercased().trimmingCharacters(in: .whitespaces),
                                      password: password)
                await AppState.shared.loadFromSupabase()
            } catch {
                await MainActor.run {
                    errorMsg = "Correo o contraseña incorrectos."
                    isLoading = false
                }
            }
        }
    }

}

// MARK: - Reset Password View
struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isSent = false
    @State private var isLoading = false
    @State private var error = ""

    var body: some View {
        NavigationView {
            ZStack {
                TinkaBackgroundView(style: .dark)
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)
                    Image(systemName: "lock.rotation").font(.system(size: 50))
                        .foregroundStyle(AnyShapeStyle(LinearGradient.tinkaPrimary))
                    Text("Recuperar contraseña")
                        .font(.tinka(22, weight: .bold)).foregroundColor(.white)
                    if isSent {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40)).foregroundColor(TinkaColor.green)
                            Text("¡Listo! Revisa tu correo para continuar.")
                                .font(.tinka(15)).foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        VStack(spacing: 16) {
                            TextField(text: $email, prompt: Text("Correo electrónico").foregroundColor(.white.opacity(0.58))) {
                                Text("Correo electrónico")
                            }
                                .font(.tinka(15)).foregroundColor(.white)
                                .keyboardType(.emailAddress).autocapitalization(.none)
                                .autocorrectionDisabled()
                                .padding(16)
                                .background(Color.white.opacity(0.14))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.22)))
                            if !error.isEmpty {
                                Text(error).font(.tinka(13)).foregroundColor(TinkaColor.red)
                            }
                            Button {
                                isLoading = true; error = ""
                                Task {
                                    do {
                                        try await AuthService.shared.sendPasswordReset(email: email)
                                        await MainActor.run { isSent = true; isLoading = false }
                                    } catch {
                                        await MainActor.run {
                                            self.error = "No se pudo enviar el correo."
                                            isLoading = false
                                        }
                                    }
                                }
                            } label: {
                                Text(isLoading ? "Enviando..." : "Enviar enlace")
                                    .font(.tinka(16, weight: .bold)).foregroundColor(.white)
                                    .frame(maxWidth: .infinity).frame(height: 52)
                                    .background(LinearGradient.tinkaPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(isLoading || email.isEmpty)
                        }
                    }
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }.foregroundColor(TinkaColor.royalPurple)
                }
            }
        }
    }
}

#Preview { LoginView() }
