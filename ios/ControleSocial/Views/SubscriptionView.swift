import SwiftUI

struct SubscriptionView: View {
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isProcessing = false
    @State private var showSuccess = false
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerSection
                    .padding(.top, 20)

                featuresSection

                plansSection

                subscribeButton

                footerSection
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .alert("Assinatura Ativada!", isPresented: $showSuccess) {
            Button("Começar") { onContinue() }
        } message: {
            Text("Sua assinatura foi ativada com sucesso. Aproveite todos os recursos!")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.15), .yellow.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 76, height: 76)
                    .shadow(color: .orange.opacity(0.3), radius: 12, y: 6)

                Image(systemName: "crown.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white)
            }

            Text("Desbloqueie o\nControle Social")
                .font(.system(.title2, weight: .bold))
                .multilineTextAlignment(.center)

            Text("Automatize suas redes sociais com inteligência artificial de última geração")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(icon: "sparkles", color: .purple, title: "IA gera legendas e imagens", subtitle: "Conteúdo profissional automático")
            FeatureRow(icon: "calendar.badge.clock", color: .blue, title: "Agendamento automático", subtitle: "Publique nos melhores horários")
            FeatureRow(icon: "chart.bar.fill", color: .green, title: "Métricas detalhadas", subtitle: "Acompanhe o crescimento")
            FeatureRow(icon: "link", color: .orange, title: "Instagram, Facebook e TikTok", subtitle: "Todas as redes em um só lugar")
            FeatureRow(icon: "infinity", color: .pink, title: "Posts ilimitados", subtitle: "Sem limites de publicação")
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }

    private var plansSection: some View {
        VStack(spacing: 12) {
            ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedPlan = plan }
                } label: {
                    PlanCard(plan: plan, isSelected: selectedPlan == plan)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: selectedPlan)
            }
        }
    }

    private var subscribeButton: some View {
        VStack(spacing: 14) {
            Button {
                Task {
                    isProcessing = true
                    try? await Task.sleep(for: .seconds(1.5))
                    isProcessing = false
                    showSuccess = true
                }
            } label: {
                HStack(spacing: 8) {
                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Assinar \(selectedPlan.displayName)")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.15, green: 0.6, blue: 0.35)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 14))
                .shadow(color: .green.opacity(0.2), radius: 8, y: 4)
            }
            .disabled(isProcessing)

            Button("Restaurar Compra") {}
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var footerSection: some View {
        VStack(spacing: 10) {
            Button("Continuar com teste grátis (7 dias)") {
                onContinue()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.green)

            Text("Cancele a qualquer momento.\nSem compromisso.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }
}

enum SubscriptionPlan: String, CaseIterable {
    case monthly
    case yearly

    var displayName: String {
        switch self {
        case .monthly: return "Mensal"
        case .yearly: return "Anual"
        }
    }

    var price: String {
        switch self {
        case .monthly: return "R$ 49,90"
        case .yearly: return "R$ 399,90"
        }
    }

    var period: String {
        switch self {
        case .monthly: return "/mês"
        case .yearly: return "/ano"
        }
    }

    var savings: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "Economia de 33%"
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color.gradient)
                .clipShape(.rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .strokeBorder(isSelected ? Color.green : Color(.separator), lineWidth: 2)
                    .frame(width: 24, height: 24)
                if isSelected {
                    Circle()
                        .fill(.green)
                        .frame(width: 14, height: 14)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(plan.displayName)
                        .font(.headline)
                    if let savings = plan.savings {
                        Text(savings)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                LinearGradient(colors: [.orange, .red.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                    }
                }
                if plan == .yearly {
                    Text("R$ 33,33/mês")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(plan.price)
                    .font(.headline)
                Text(plan.period)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(isSelected ? Color.green : Color.clear, lineWidth: 2)
                )
        )
    }
}
