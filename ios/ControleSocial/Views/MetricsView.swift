import SwiftUI

struct MetricsView: View {
    let viewModel: DashboardViewModel
    @State private var selectedPeriod: MetricsPeriod = .thirtyDays
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                periodPicker
                if let metrics = viewModel.metrics {
                    platformCards(metrics)
                    engagementOverview(metrics)
                    topPostsSection
                    insightsSection(metrics)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Métricas")
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }

    private var periodPicker: some View {
        Picker("Período", selection: $selectedPeriod) {
            ForEach(MetricsPeriod.allCases, id: \.self) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private func platformCards(_ metrics: MetricsSummary) -> some View {
        VStack(spacing: 12) {
            PlatformMetricCard(
                platform: "Instagram",
                icon: "camera.fill",
                gradient: [Color(red: 0.83, green: 0.18, blue: 0.55), Color(red: 0.98, green: 0.35, blue: 0.13)],
                reach: metrics.instagramReach,
                reachChange: metrics.instagramReachChange,
                likes: metrics.instagramLikes,
                comments: metrics.instagramComments
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            PlatformMetricCard(
                platform: "Facebook",
                icon: "person.2.fill",
                gradient: [Color(red: 0.23, green: 0.35, blue: 0.6), Color(red: 0.35, green: 0.5, blue: 0.8)],
                reach: metrics.facebookReach,
                reachChange: metrics.facebookReachChange,
                likes: metrics.facebookLikes,
                comments: metrics.facebookComments
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            PlatformMetricCard(
                platform: "TikTok",
                icon: "music.note",
                gradient: [Color(.label).opacity(0.85), Color(.secondaryLabel)],
                reach: metrics.tiktokViews,
                reachChange: metrics.tiktokViewsChange,
                likes: metrics.tiktokLikes,
                comments: 0
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)
        }
    }

    private func engagementOverview(_ metrics: MetricsSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
                Text("Visão Geral")
                    .font(.headline)
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                OverviewCell(title: "Total Posts", value: "\(metrics.totalPosts)", icon: "doc.text.fill", color: .blue)
                OverviewCell(title: "Publicados", value: "\(metrics.publishedPosts)", icon: "checkmark.circle.fill", color: .green)
                OverviewCell(title: "Falhas", value: "\(metrics.failedPosts)", icon: "exclamationmark.triangle.fill", color: .red)
                OverviewCell(title: "Taxa Sucesso", value: "\(Int(Double(metrics.publishedPosts) / Double(max(metrics.totalPosts, 1)) * 100))%", icon: "chart.line.uptrend.xyaxis", color: .teal)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var topPostsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                Text("Top 5 Posts")
                    .font(.headline)
                Spacer()
            }

            let topPosts = viewModel.posts
                .filter { $0.status == .published }
                .sorted { $0.totalEngagement > $1.totalEngagement }
                .prefix(5)

            if topPosts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Nenhum post publicado ainda")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(Array(topPosts.enumerated()), id: \.element.id) { index, post in
                    HStack(spacing: 12) {
                        Text("#\(index + 1)")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(index == 0 ? .orange : .secondary)
                            .frame(width: 32)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(post.category.tintColor.opacity(0.12))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: post.category.icon)
                                    .foregroundStyle(post.category.tintColor)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.category.displayName)
                                .font(.subheadline.weight(.medium))
                            Text(post.scheduledFor.formatted(.dateTime.day().month(.abbreviated)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(NumberFormatter.compact(post.totalEngagement))
                                .font(.subheadline.weight(.bold))
                            Text("engajamento")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    if index < min(topPosts.count - 1, 4) {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private func insightsSection(_ metrics: MetricsSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .font(.title3)
                Text("Insights")
                    .font(.headline)
                Spacer()
            }

            InsightRow(icon: "clock.fill", color: .blue, title: "Melhor Horário", value: metrics.bestHour, detail: "Engajamento 3x maior")
            Divider()
            InsightRow(icon: "star.fill", color: .orange, title: "Melhor Categoria", value: metrics.bestCategory, detail: "CTR 4.2%")
            Divider()
            InsightRow(icon: "arrow.up.right", color: .green, title: "Crescimento", value: "+\(Int(metrics.instagramReachChange))%", detail: "Alcance Instagram vs mês anterior")
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }
}

enum MetricsPeriod: String, CaseIterable {
    case sevenDays = "7d"
    case thirtyDays = "30d"
    case ninetyDays = "90d"

    var displayName: String {
        switch self {
        case .sevenDays: return "7 dias"
        case .thirtyDays: return "30 dias"
        case .ninetyDays: return "90 dias"
        }
    }
}

struct PlatformMetricCard: View {
    let platform: String
    let icon: String
    let gradient: [Color]
    let reach: Int
    let reachChange: Double
    let likes: Int
    let comments: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(platform)
                    .font(.headline)
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: reachChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(reachChange >= 0 ? "+" : "")\(Int(reachChange))%")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white.opacity(0.85))
            }

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(NumberFormatter.compact(reach))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("Alcance")
                        .font(.caption)
                        .opacity(0.8)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(NumberFormatter.compact(likes))
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Text("Curtidas")
                        .font(.caption)
                        .opacity(0.8)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(NumberFormatter.compact(comments))
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Text("Coment.")
                        .font(.caption)
                        .opacity(0.8)
                }
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(.rect(cornerRadius: 16))
    }
}

struct OverviewCell: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color.gradient)
                .clipShape(.rect(cornerRadius: 8))
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }
}

struct InsightRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color.gradient)
                .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
        }
        .padding(.vertical, 2)
    }
}
