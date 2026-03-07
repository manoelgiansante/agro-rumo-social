import SwiftUI

struct DashboardView: View {
    let viewModel: DashboardViewModel
    @State private var showingPostDetail: Post?
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                greetingHeader
                statusOverview
                if !viewModel.pendingReviewPosts.isEmpty {
                    pendingReviewSection
                }
                if !viewModel.failedPosts.isEmpty {
                    failedPostsAlert
                }
                weekScheduleSection
                if let metrics = viewModel.metrics {
                    quickMetricsSection(metrics)
                }
                accountsStatusSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
        .refreshable {
            await viewModel.loadData()
        }
        .sheet(item: $showingPostDetail) { post in
            NavigationStack {
                PostDetailView(post: post, viewModel: viewModel)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }

    private var greetingHeader: some View {
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
                    .frame(width: 44, height: 44)

                Text(userInitials)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(userName)
                    .font(.title3.weight(.semibold))
            }

            Spacer()

            if viewModel.isLoading {
                ProgressView()
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var statusOverview: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatusCard(
                title: "Hoje",
                value: "\(viewModel.todaysPosts.count)",
                subtitle: "posts agendados",
                icon: "calendar.badge.clock",
                color: .blue
            )
            StatusCard(
                title: "Publicados",
                value: "\(viewModel.publishedCount)",
                subtitle: "últimos 30 dias",
                icon: "checkmark.circle.fill",
                color: .green
            )
            StatusCard(
                title: "Aguardando",
                value: "\(viewModel.pendingReviewPosts.count)",
                subtitle: "para aprovação",
                icon: "eye.circle",
                color: .orange
            )
            StatusCard(
                title: "Falhas",
                value: "\(viewModel.failedPosts.count)",
                subtitle: "necessitam ação",
                icon: "exclamationmark.triangle",
                color: .red
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }

    private var pendingReviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "eye.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                Text("Aguardando Aprovação")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.pendingReviewPosts.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.12))
                    .clipShape(Capsule())
            }

            ForEach(viewModel.pendingReviewPosts.prefix(3)) { post in
                Button {
                    showingPostDetail = post
                } label: {
                    PendingPostRow(post: post)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var failedPostsAlert: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
                Text("Posts com Falha")
                    .font(.headline)
                Spacer()
            }

            ForEach(viewModel.failedPosts.prefix(3)) { post in
                Button {
                    showingPostDetail = post
                } label: {
                    FailedPostRow(post: post, onRetry: {
                        viewModel.retryPost(post)
                    })
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var weekScheduleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
                    .font(.title3)
                Text("Esta Semana")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.weeklyPosts.count) posts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.weeklyPosts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Nenhum post agendado")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(viewModel.weeklyPosts.prefix(5)) { post in
                    Button {
                        showingPostDetail = post
                    } label: {
                        WeekPostRow(post: post)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private func quickMetricsSection(_ metrics: MetricsSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.purple)
                    .font(.title3)
                Text("Resumo 30 dias")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 10) {
                MetricPill(platform: "Instagram", icon: "camera", value: NumberFormatter.compact(metrics.instagramReach), label: "Alcance", change: metrics.instagramReachChange, color: .pink)
                MetricPill(platform: "Facebook", icon: "person.2", value: NumberFormatter.compact(metrics.facebookReach), label: "Alcance", change: metrics.facebookReachChange, color: .blue)
                MetricPill(platform: "TikTok", icon: "music.note", value: NumberFormatter.compact(metrics.tiktokViews), label: "Views", change: metrics.tiktokViewsChange, color: .primary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var accountsStatusSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .foregroundStyle(.teal)
                    .font(.title3)
                Text("Contas Conectadas")
                    .font(.headline)
                Spacer()
            }

            ForEach(viewModel.accounts) { account in
                HStack(spacing: 12) {
                    Image(systemName: account.platform.icon)
                        .font(.title3)
                        .foregroundStyle(account.isActive ? platformColor(account.platform) : .secondary)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.accountName)
                            .font(.subheadline.weight(.medium))
                        Text(account.platform.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 5) {
                        Circle()
                            .fill(account.isActive ? .green : .red)
                            .frame(width: 7, height: 7)
                        Text(account.isActive ? "Ativo" : "Inativo")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(account.isActive ? .green : .red)
                    }
                }
                .padding(.vertical, 4)
            }

            if viewModel.accounts.isEmpty {
                HStack {
                    Image(systemName: "link.badge.plus")
                        .foregroundStyle(.secondary)
                    Text("Nenhuma conta conectada")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private func platformColor(_ platform: SocialPlatform) -> Color {
        switch platform {
        case .instagram: return .pink
        case .facebook: return .blue
        case .tiktok: return .primary
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Bom dia" }
        if hour < 18 { return "Boa tarde" }
        return "Boa noite"
    }

    private var userName: String {
        let name = AuthService.shared.userProfile?.fullName ?? AuthService.shared.currentUser?.email ?? "Usuário"
        return name.split(separator: " ").first.map(String.init) ?? name
    }

    private var userInitials: String {
        let name = AuthService.shared.userProfile?.fullName ?? AuthService.shared.currentUser?.email ?? "U"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

struct StatusCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(color.gradient)
                    .clipShape(.rect(cornerRadius: 8))
                Spacer()
            }
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }
}

struct PendingPostRow: View {
    let post: Post

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(post.category.tintColor.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: post.category.icon)
                        .foregroundStyle(post.category.tintColor)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(post.category.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text(post.scheduledFor, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct FailedPostRow: View {
    let post: Post
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(post.category.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text("Tentativa \(post.retryCount)/3")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            Button {
                onRetry()
            } label: {
                Text("Tentar")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.red.opacity(0.12))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

struct WeekPostRow: View {
    let post: Post

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(post.scheduledFor.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(post.scheduledFor.formatted(.dateTime.day()))
                    .font(.title3.weight(.bold))
            }
            .frame(width: 44)

            RoundedRectangle(cornerRadius: 8)
                .fill(post.category.tintColor.opacity(0.12))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: post.category.icon)
                        .font(.subheadline)
                        .foregroundStyle(post.category.tintColor)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(post.category.displayName)
                    .font(.subheadline.weight(.medium))
                Text(post.scheduledFor.formatted(.dateTime.hour().minute()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: post.status.icon)
                .foregroundStyle(post.status.color)
        }
        .padding(.vertical, 4)
    }
}

struct MetricPill: View {
    let platform: String
    let icon: String
    let value: String
    let label: String
    let change: Double
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            if change > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8, weight: .bold))
                    Text("+\(Int(change))%")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }
}
