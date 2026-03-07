import SwiftUI

struct ConnectAccountView: View {
    let viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var oauthService = OAuthService()
    @State private var connectingPlatform: SocialPlatform?
    @State private var showSuccess = false
    @State private var successMessage = ""

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    Text("Conecte suas redes sociais para publicar automaticamente. O login é feito diretamente na plataforma oficial — nunca armazenamos sua senha.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
            }

            Section {
                ForEach(SocialPlatform.allCases, id: \.self) { platform in
                    let connected = viewModel.accounts.first(where: { $0.platform == platform && $0.isActive })
                    PlatformConnectionRow(
                        platform: platform,
                        account: connected,
                        isConnecting: connectingPlatform == platform,
                        onConnect: { connectPlatform(platform) },
                        onDisconnect: {
                            if let acc = connected {
                                viewModel.removeAccount(acc)
                            }
                        }
                    )
                }
            } header: {
                Text("Plataformas")
            } footer: {
                Text("Utilizamos OAuth oficial. Seus tokens são criptografados e podem ser revogados a qualquer momento.")
            }

            Section {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Como funciona?", systemImage: "questionmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(number: "1", text: "Você clica em \"Conectar\"")
                        InfoRow(number: "2", text: "Abre a tela oficial da plataforma")
                        InfoRow(number: "3", text: "Você faz login direto na plataforma")
                        InfoRow(number: "4", text: "A plataforma nos dá um token de acesso")
                        InfoRow(number: "5", text: "Usamos o token para publicar por você")
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Segurança")
            } footer: {
                Text("Sua senha nunca passa pelo nosso sistema. É o mesmo padrão usado por Buffer, Hootsuite e mLabs.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Conectar Redes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fechar") { dismiss() }
            }
        }
        .overlay {
            if oauthService.isAuthenticating {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Conectando...")
                                .font(.headline)
                            Text("Aguarde a tela de login")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(32)
                        .background(.ultraThickMaterial)
                        .clipShape(.rect(cornerRadius: 20))
                    }
            }
        }
        .alert("Conectado!", isPresented: $showSuccess) {
            Button("OK") {}
        } message: {
            Text(successMessage)
        }
        .alert("Erro", isPresented: .init(
            get: { oauthService.authError != nil },
            set: { if !$0 { oauthService.authError = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(oauthService.authError ?? "")
        }
    }

    private var currentUserId: String {
        AuthService.shared.currentUser?.id ?? ""
    }

    private func connectPlatform(_ platform: SocialPlatform) {
        connectingPlatform = platform
        Task {
            switch platform {
            case .instagram, .facebook:
                await connectMeta(platform: platform)
            case .tiktok:
                await connectTikTok()
            }
            connectingPlatform = nil
        }
    }

    private func connectMeta(platform: SocialPlatform) async {
        guard let result = await oauthService.connectMeta(userId: currentUserId) else { return }

        await viewModel.loadData()

        let platforms = result.connectedPlatforms
        var parts: [String] = []
        if platforms.contains("facebook") { parts.append("Facebook") }
        if platforms.contains("instagram") { parts.append("Instagram") }
        successMessage = parts.isEmpty
            ? "Conta Meta conectada com sucesso!"
            : "\(parts.joined(separator: " e ")) conectado(s) com sucesso!"
        showSuccess = true
    }

    private func connectTikTok() async {
        guard let result = await oauthService.connectTikTok(userId: currentUserId) else { return }

        await viewModel.loadData()

        successMessage = "TikTok conectado com sucesso!"
        showSuccess = true
    }
}

struct PlatformConnectionRow: View {
    let platform: SocialPlatform
    let account: SocialAccount?
    let isConnecting: Bool
    let onConnect: () -> Void
    let onDisconnect: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(platformColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: platform.icon)
                    .font(.title3)
                    .foregroundStyle(platformColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(platform.displayName)
                    .font(.body.weight(.medium))
                if let account {
                    Text(account.accountName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Não conectado")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isConnecting {
                ProgressView()
            } else if account != nil {
                Menu {
                    Button(role: .destructive) {
                        onDisconnect()
                    } label: {
                        Label("Desconectar", systemImage: "xmark.circle")
                    }
                    Button {
                        onConnect()
                    } label: {
                        Label("Reconectar", systemImage: "arrow.clockwise")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 7, height: 7)
                        Text("Conectado")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.green.opacity(0.1))
                    .clipShape(Capsule())
                }
            } else {
                Button {
                    onConnect()
                } label: {
                    Text("Conectar")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(platformColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var platformColor: Color {
        switch platform {
        case .instagram: return .pink
        case .facebook: return .blue
        case .tiktok: return .primary
        }
    }
}

struct InfoRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.green.gradient)
                .clipShape(Circle())
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
