import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage: Int = 0
    @State private var appeared: Bool = false
    @State private var iconBounce: Int = 0

    private let totalPages = 3

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                TabView(selection: $currentPage) {
                    page1.tag(0)
                    page2.tag(1)
                    page3.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomControls
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.15)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                iconBounce += 1
            }
        }
        .onChange(of: currentPage) { _, _ in
            iconBounce += 1
        }
    }

    // MARK: - Page 1: Hero / Value Prop

    private var page1: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.2), Color.purple.opacity(0.05), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .blur(radius: 8)

                mockPhoneUI
            }
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 14) {
                Text("Suas redes sociais\nno piloto automático")
                    .font(.system(.title, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text("A IA cria, agenda e publica conteúdo profissional enquanto você foca no que importa.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 32)

            socialProofBadge(text: "Usado por +2.000 criadores", icon: "person.2.fill")
                .padding(.top, 24)

            Spacer()
            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Page 2: Features

    private var page2: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.blue.opacity(0.15), Color.cyan.opacity(0.05), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .blur(radius: 10)

                VStack(spacing: 16) {
                    featureCard(
                        icon: "sparkles",
                        iconColor: .purple,
                        title: "IA Cria Conteúdo",
                        subtitle: "Legendas, hashtags e imagens",
                        delay: 0.0
                    )
                    featureCard(
                        icon: "calendar.badge.clock",
                        iconColor: .blue,
                        title: "Agendamento Inteligente",
                        subtitle: "Publique no melhor horário",
                        delay: 0.08
                    )
                    featureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .green,
                        title: "Métricas Unificadas",
                        subtitle: "Instagram, Facebook e TikTok",
                        delay: 0.16
                    )
                }
            }
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 14) {
                Text("Tudo que você precisa\nem um só lugar")
                    .font(.system(.title2, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text("Pare de alternar entre apps. Gerencie tudo de forma centralizada e automatizada.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 28)
            }
            .padding(.top, 28)

            Spacer()
            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Page 3: CTA

    private var page3: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.green.opacity(0.3 - Double(i) * 0.08),
                                    Color.mint.opacity(0.2 - Double(i) * 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: CGFloat(120 + i * 50), height: CGFloat(120 + i * 50))
                        .rotationEffect(.degrees(Double(i * 30)))
                }

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.75, blue: 0.45), Color(red: 0.1, green: 0.55, blue: 0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .green.opacity(0.35), radius: 20, y: 8)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: iconBounce)
                }
            }
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 14) {
                Text("Comece agora\ne veja resultados")
                    .font(.system(.title, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text("Crie sua conta em segundos.\nSem cartão de crédito. Sem compromisso.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 28)
            }
            .padding(.top, 32)

            HStack(spacing: 24) {
                statBadge(value: "3x", label: "mais alcance")
                statBadge(value: "70%", label: "menos tempo")
                statBadge(value: "24/7", label: "automação")
            }
            .padding(.top, 24)

            Spacer()
            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Components

    private var backgroundGradient: some View {
        ZStack {
            Color(.systemBackground)

            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: meshColors
            )
            .opacity(0.7)
        }
    }

    private var meshColors: [Color] {
        switch currentPage {
        case 0:
            return [
                .purple.opacity(0.12), .clear, .pink.opacity(0.06),
                .clear, .clear, .clear,
                .blue.opacity(0.06), .clear, .purple.opacity(0.08)
            ]
        case 1:
            return [
                .blue.opacity(0.1), .clear, .cyan.opacity(0.08),
                .clear, .clear, .clear,
                .teal.opacity(0.06), .clear, .blue.opacity(0.06)
            ]
        default:
            return [
                .green.opacity(0.12), .clear, .mint.opacity(0.08),
                .clear, .clear, .clear,
                .teal.opacity(0.06), .clear, .green.opacity(0.1)
            ]
        }
    }

    private var mockPhoneUI: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray4))
                        .frame(width: 60, height: 8)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(width: 40, height: 6)
                }
                Spacer()
                Circle()
                    .fill(
                        LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }

            HStack(spacing: 8) {
                mockMetricPill(value: "12.4K", label: "Alcance", color: .blue)
                mockMetricPill(value: "8.2%", label: "Engaj.", color: .green)
                mockMetricPill(value: "+340", label: "Seguid.", color: .purple)
            }

            HStack(spacing: 6) {
                ForEach(["instagram", "facebook", "play.rectangle.fill"], id: \.self) { icon in
                    let systemIcon = icon == "instagram" ? "camera.circle.fill" :
                                     icon == "facebook" ? "person.circle.fill" : icon
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: 32)
                        .overlay {
                            HStack(spacing: 4) {
                                Image(systemName: systemIcon)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(.systemGray4))
                                    .frame(width: 24, height: 5)
                            }
                        }
                }
            }
        }
        .padding(16)
        .frame(width: 220)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }

    private func mockMetricPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.caption, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .clipShape(.rect(cornerRadius: 8))
    }

    private func featureCard(icon: String, iconColor: Color, title: String, subtitle: String, delay: Double) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .symbolEffect(.bounce, value: iconBounce)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.body)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private func socialProofBadge(text: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.green)
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, weight: .bold))
                .foregroundStyle(Color(red: 0.2, green: 0.7, blue: 0.4))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage
                              ? Color(red: 0.2, green: 0.7, blue: 0.4)
                              : Color(.separator))
                        .frame(width: index == currentPage ? 28 : 8, height: 8)
                        .animation(.spring(response: 0.35), value: currentPage)
                }
            }

            if currentPage < totalPages - 1 {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        currentPage += 1
                    }
                } label: {
                    Text("Continuar")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.12, green: 0.55, blue: 0.35)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 14))
                        .shadow(color: .green.opacity(0.2), radius: 10, y: 5)
                }

                Button("Pular") {
                    onComplete()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            } else {
                Button {
                    onComplete()
                } label: {
                    HStack(spacing: 8) {
                        Text("Criar Minha Conta")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.12, green: 0.55, blue: 0.35)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 14))
                    .shadow(color: .green.opacity(0.25), radius: 12, y: 5)
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: currentPage)

                Button("Já tenho conta") {
                    onComplete()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(red: 0.2, green: 0.65, blue: 0.4))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
}
