import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var authService
    @State private var hasCheckedSession = false
    @State private var splashPhase: SplashPhase = .logo
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if !hasCheckedSession {
                splashView
            } else if !hasCompletedOnboarding {
                OnboardingView {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else if !authService.isAuthenticated {
                LoginView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96)),
                        removal: .opacity
                    ))
            } else {
                ContentView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: hasCheckedSession)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: authService.isAuthenticated)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: hasCompletedOnboarding)
        .task {
            await authService.checkSession()
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                hasCheckedSession = true
            }
        }
    }

    private var splashView: some View {
        ZStack {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    .green.opacity(0.3), .mint.opacity(0.2), .teal.opacity(0.15),
                    .green.opacity(0.15), Color(.systemBackground), .cyan.opacity(0.1),
                    .mint.opacity(0.1), .green.opacity(0.2), .teal.opacity(0.2)
                ]
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.55, blue: 0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .green.opacity(0.3), radius: 20, y: 10)
                        .scaleEffect(splashPhase == .logo ? 0.5 : 1.0)
                        .opacity(splashPhase == .logo ? 0 : 1)

                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                        .scaleEffect(splashPhase == .logo ? 0.5 : 1.0)
                        .opacity(splashPhase == .logo ? 0 : 1)
                        .symbolEffect(.bounce, value: splashPhase)
                }

                VStack(spacing: 8) {
                    Text("Controle Social")
                        .font(.system(.title, weight: .bold))
                        .opacity(splashPhase.rawValue >= SplashPhase.text.rawValue ? 1 : 0)
                        .offset(y: splashPhase.rawValue >= SplashPhase.text.rawValue ? 0 : 12)

                    Text("Automação inteligente")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .opacity(splashPhase.rawValue >= SplashPhase.subtitle.rawValue ? 1 : 0)
                        .offset(y: splashPhase.rawValue >= SplashPhase.subtitle.rawValue ? 0 : 8)
                }
                .padding(.top, 24)

                Spacer()

                ProgressView()
                    .tint(.green)
                    .scaleEffect(1.1)
                    .opacity(splashPhase.rawValue >= SplashPhase.loading.rawValue ? 1 : 0)
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                splashPhase = .icon
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4)) {
                splashPhase = .text
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
                splashPhase = .subtitle
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.8)) {
                splashPhase = .loading
            }
        }
    }
}

private enum SplashPhase: Int {
    case logo = 0
    case icon = 1
    case text = 2
    case subtitle = 3
    case loading = 4
}
