import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isSignUp = false
    @State private var showForgotPassword = false
    @State private var appeared = false

    private enum FocusField { case name, email, password }
    @FocusState private var focusedField: FocusField?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                    .padding(.top, 48)
                    .padding(.bottom, 36)

                formSection
                    .padding(.horizontal, 24)

                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                socialLoginSection
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                toggleSection
                    .padding(.top, 24)

                Spacer(minLength: 40)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(
            ZStack {
                Color(.systemBackground)
                MeshGradient(
                    width: 3, height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: [
                        .green.opacity(0.12), .clear, .teal.opacity(0.08),
                        .clear, .clear, .clear,
                        .mint.opacity(0.06), .clear, .green.opacity(0.06)
                    ]
                )
            }
            .ignoresSafeArea()
        )
        .alert("Recuperar Senha", isPresented: $showForgotPassword) {
            TextField("Seu email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
            Button("Enviar") {}
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Digite seu email para receber o link de recuperação.")
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.55, blue: 0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: .green.opacity(0.25), radius: 16, y: 8)

                Image(systemName: "megaphone.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.white)
            }
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 6) {
                Text("Controle Social")
                    .font(.system(.title, weight: .bold))

                Text(isSignUp ? "Crie sua conta gratuitamente" : "Entre na sua conta")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
        }
    }

    private var formSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                if isSignUp {
                    fieldRow(icon: "person", placeholder: "Nome completo", text: $fullName, field: .name)
                    Divider().padding(.leading, 48)
                }

                fieldRow(icon: "envelope", placeholder: "Email", text: $email, field: .email, keyboard: .emailAddress, content: .emailAddress)
                Divider().padding(.leading, 48)

                HStack(spacing: 12) {
                    Image(systemName: "lock")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    SecureField("Senha", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                        .focused($focusedField, equals: .password)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 4)

            if !isSignUp {
                HStack {
                    Spacer()
                    Button("Esqueci a senha") {
                        showForgotPassword = true
                    }
                    .font(.caption)
                    .foregroundStyle(.green.opacity(0.8))
                    .padding(.top, 8)
                    .padding(.trailing, 4)
                }
            }
        }
    }

    private func fieldRow(icon: String, placeholder: String, text: Binding<String>, field: FocusField, keyboard: UIKeyboardType = .default, content: UITextContentType? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .focused($focusedField, equals: field)
                .onSubmit {
                    switch field {
                    case .name: focusedField = .email
                    case .email: focusedField = .password
                    case .password: break
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            if let error = authService.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.08))
                .clipShape(.rect(cornerRadius: 12))
                .transition(.scale.combined(with: .opacity))
            }

            if let success = authService.signUpSuccessMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(success)
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.15, green: 0.55, blue: 0.3))
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.08))
                .clipShape(.rect(cornerRadius: 12))
                .transition(.scale.combined(with: .opacity))
            }

            Button {
                Task { await performAuth() }
            } label: {
                HStack(spacing: 8) {
                    if authService.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isSignUp ? "Criar Conta" : "Entrar")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isFormValid
                            ? [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.15, green: 0.6, blue: 0.35)]
                            : [Color(.systemGray4), Color(.systemGray4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 14))
                .shadow(color: isFormValid ? .green.opacity(0.2) : .clear, radius: 8, y: 4)
            }
            .disabled(authService.isLoading || !isFormValid)
            .sensoryFeedback(.impact(weight: .medium), trigger: authService.isAuthenticated)
        }
        .animation(.spring(response: 0.3), value: authService.errorMessage != nil)
    }

    private var socialLoginSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 0.5)
                Text("ou")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 0.5)
            }

            SignInWithAppleButton(.signIn) { request in
                let nonce = authService.generateNonce()
                request.requestedScopes = [.email, .fullName]
                request.nonce = authService.sha256(nonce)
            } onCompletion: { result in
                Task { await handleAppleSignIn(result) }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(.rect(cornerRadius: 14))
        }
    }

    private var toggleSection: some View {
        VStack(spacing: 20) {
            HStack(spacing: 4) {
                Text(isSignUp ? "Já tem conta?" : "Não tem conta?")
                    .foregroundStyle(.secondary)
                Button(isSignUp ? "Fazer login" : "Criar conta") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isSignUp.toggle()
                        authService.errorMessage = nil
                        focusedField = nil
                    }
                }
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.2, green: 0.65, blue: 0.4))
            }
            .font(.subheadline)

            Text("Ao continuar, você concorda com os\nTermos de Uso e Política de Privacidade")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6
        if isSignUp {
            return emailValid && passwordValid && !fullName.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return emailValid && passwordValid
    }

    private func performAuth() async {
        focusedField = nil
        do {
            if isSignUp {
                try await authService.signUp(email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), password: password, fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines))
            } else {
                try await authService.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), password: password)
            }
        } catch {
            if authService.errorMessage == nil {
                authService.errorMessage = "Erro inesperado. Tente novamente."
            }
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, any Error>) async {
        switch result {
        case .success(let authorization):
            do {
                try await authService.signInWithApple(authorization: authorization)
            } catch {
                if authService.errorMessage == nil {
                    authService.errorMessage = "Erro ao entrar com Apple. Tente novamente."
                }
            }
        case .failure:
            authService.errorMessage = "Login com Apple cancelado ou falhou."
        }
    }
}
