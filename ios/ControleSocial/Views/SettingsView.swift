import SwiftUI

struct SettingsView: View {
    let viewModel: DashboardViewModel
    @State private var authService = AuthService.shared
    @State private var publishMode: PublishMode = .withApproval
    @State private var morningTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var afternoonTime = Calendar.current.date(from: DateComponents(hour: 17, minute: 30)) ?? Date()
    @State private var brandTone: String = "Profissional, próximo, conhecedor do agro brasileiro. Fala a língua do produtor rural sem ser informal demais."
    @State private var showingEditTone = false
    @State private var showingConnectAccounts = false
    @State private var isGenerating = false
    @State private var generationMessage: String?
    @State private var showLogoutAlert = false
    @State private var showSubscription = false

    var body: some View {
        List {
            profileSection
            subscriptionSection
            connectedAccountsSection
            quickActionsSection
            publishScheduleSection
            publishModeSection
            calendarSection
            brandSection
            aboutSection
            logoutSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Configurações")
        .sheet(isPresented: $showingEditTone) {
            NavigationStack {
                EditToneSheet(brandTone: $brandTone)
            }
        }
        .sheet(isPresented: $showingConnectAccounts) {
            NavigationStack {
                ConnectAccountView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showSubscription) {
            NavigationStack {
                SubscriptionView { showSubscription = false }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fechar") { showSubscription = false }
                        }
                    }
            }
        }
        .alert("Geração de Conteúdo", isPresented: .init(
            get: { generationMessage != nil },
            set: { if !$0 { generationMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(generationMessage ?? "")
        }
        .alert("Sair da Conta", isPresented: $showLogoutAlert) {
            Button("Sair", role: .destructive) {
                authService.signOut()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Tem certeza que deseja sair? Você precisará fazer login novamente.")
        }
    }

    private var profileSection: some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.15, green: 0.6, blue: 0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Text(initials)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(authService.userProfile?.fullName ?? authService.currentUser?.email ?? "Usuário")
                        .font(.headline)
                    if let email = authService.currentUser?.email {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var subscriptionSection: some View {
        Section {
            Button {
                showSubscription = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Plano Atual")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text(subscriptionStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("Gerenciar")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.orange.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .buttonStyle(.plain)
        } header: {
            Text("Assinatura")
        }
    }

    private var connectedAccountsSection: some View {
        Section {
            ForEach(SocialPlatform.allCases, id: \.self) { platform in
                let account = viewModel.accounts.first(where: { $0.platform == platform })
                HStack(spacing: 12) {
                    Image(systemName: platform.icon)
                        .font(.title3)
                        .foregroundStyle(account?.isActive == true ? platformColor(platform) : .secondary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(account?.accountName ?? platform.displayName)
                            .font(.body)
                        if let account, account.isActive {
                            if let expires = account.tokenExpiresAt {
                                Text("Token expira: \(expires.formatted(.dateTime.day().month().year()))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Não conectado")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if account?.isActive == true {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(.green)
                                .frame(width: 7, height: 7)
                            Text("Ativo")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.green)
                        }
                    } else {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(.red)
                                .frame(width: 7, height: 7)
                            Text("Inativo")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Button {
                showingConnectAccounts = true
            } label: {
                Label("Gerenciar Conexões", systemImage: "link.badge.plus")
                    .font(.subheadline.weight(.medium))
            }
        } header: {
            Text("Contas Conectadas")
        } footer: {
            Text("Conecte suas redes sociais via OAuth. Sua senha nunca é armazenada.")
        }
    }

    private var quickActionsSection: some View {
        Section {
            Button {
                Task {
                    isGenerating = true
                    await viewModel.generateContent()
                    isGenerating = false
                    generationMessage = viewModel.errorMessage ?? "Conteúdo gerado com sucesso!"
                }
            } label: {
                HStack {
                    Label("Gerar Conteúdo Agora", systemImage: "sparkles")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    if isGenerating {
                        ProgressView()
                    }
                }
            }
            .disabled(isGenerating)

            Button {
                Task {
                    await viewModel.publishNow()
                    generationMessage = viewModel.errorMessage ?? "Publicação iniciada!"
                }
            } label: {
                Label("Publicar Posts Prontos", systemImage: "paperplane")
                    .font(.subheadline.weight(.medium))
            }
        } header: {
            Text("Ações Rápidas")
        } footer: {
            Text("Dispare manualmente a geração ou publicação dos posts.")
        }
    }

    private var publishScheduleSection: some View {
        Section {
            DatePicker("Post Manhã", selection: $morningTime, displayedComponents: .hourAndMinute)
            DatePicker("Post Tarde", selection: $afternoonTime, displayedComponents: .hourAndMinute)
        } header: {
            Text("Horários de Publicação")
        } footer: {
            Text("Horário de Brasília (BRT). Melhor horário: 7h-8h.")
        }
    }

    private var publishModeSection: some View {
        Section {
            Picker("Modo", selection: $publishMode) {
                ForEach(PublishMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.inline)
        } header: {
            Text("Modo de Publicação")
        } footer: {
            Text(publishMode == .automatic
                 ? "Posts publicados automaticamente nos horários configurados."
                 : "Posts aguardarão sua aprovação antes de publicar.")
        }
    }

    private var calendarSection: some View {
        Section {
            ForEach(viewModel.calendarEntries) { entry in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(entry.category.tintColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: entry.category.icon)
                                .font(.subheadline)
                                .foregroundStyle(entry.category.tintColor)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.category.displayName)
                            .font(.subheadline.weight(.medium))
                        Text(entry.dayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: entry.isActive ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(entry.isActive ? .green : .secondary)
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Categorias Semanais")
        } footer: {
            Text("Cada dia da semana tem uma categoria de conteúdo rotativo.")
        }
    }

    private var brandSection: some View {
        Section {
            Button {
                showingEditTone = true
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tom da Marca")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(brandTone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            LabeledContent("App URL", value: "app.controledemaquina.com.br")
                .font(.subheadline)

            LabeledContent("Hashtags", value: "15 por post")
                .font(.subheadline)
        } header: {
            Text("Configuração da Marca")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("IA Texto", value: "Claude Sonnet 4")
                .font(.subheadline)
            LabeledContent("IA Imagem", value: "Flux Pro 1.1")
                .font(.subheadline)
            LabeledContent("Backend", value: "Supabase")
                .font(.subheadline)

            HStack {
                Text("Modo")
                    .font(.subheadline)
                Spacer()
                HStack(spacing: 5) {
                    Circle()
                        .fill(viewModel.useMockData ? .orange : .green)
                        .frame(width: 7, height: 7)
                    Text(viewModel.useMockData ? "Demo" : "Produção")
                        .font(.subheadline)
                        .foregroundStyle(viewModel.useMockData ? .orange : .green)
                }
            }

            LabeledContent("Versão", value: "1.0.0")
                .font(.subheadline)
        } header: {
            Text("Sistema")
        }
    }

    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutAlert = true
            } label: {
                HStack {
                    Spacer()
                    Label("Sair da Conta", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                }
            }
        }
    }

    private func platformColor(_ platform: SocialPlatform) -> Color {
        switch platform {
        case .instagram: return .pink
        case .facebook: return .blue
        case .tiktok: return .primary
        }
    }

    private var initials: String {
        let name = authService.userProfile?.fullName ?? authService.currentUser?.email ?? "U"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var subscriptionStatusText: String {
        let status = authService.userProfile?.subscriptionStatus ?? "trial"
        switch status {
        case "active": return "Premium Ativo"
        case "trial": return "Teste Grátis (7 dias)"
        default: return "Nenhum plano ativo"
        }
    }
}

enum PublishMode: String, CaseIterable {
    case automatic
    case withApproval

    var displayName: String {
        switch self {
        case .automatic: return "Automático"
        case .withApproval: return "Com Aprovação"
        }
    }
}

struct EditToneSheet: View {
    @Binding var brandTone: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                TextEditor(text: $brandTone)
                    .frame(minHeight: 150)
            } header: {
                Text("Tom da Marca")
            } footer: {
                Text("Descreva o tom de voz que a IA deve usar ao gerar legendas e conteúdo para as redes sociais.")
            }
        }
        .navigationTitle("Editar Tom")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Salvar") { dismiss() }
            }
        }
    }
}
