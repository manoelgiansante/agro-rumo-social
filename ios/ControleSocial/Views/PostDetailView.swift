import SwiftUI

struct PostDetailView: View {
    let post: Post
    let viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editedCaption: String
    @State private var editedHashtags: String
    @State private var isEditing = false
    @State private var showApproveAlert = false
    @State private var showRejectAlert = false

    init(post: Post, viewModel: DashboardViewModel) {
        self.post = post
        self.viewModel = viewModel
        _editedCaption = State(initialValue: post.caption)
        _editedHashtags = State(initialValue: post.hashtags)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                statusBadges
                imagePreview
                captionSection
                hashtagsSection
                platformStatusSection
                if post.status == .published {
                    metricsSection
                }
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(post.category.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fechar") { dismiss() }
            }
            if post.status == .ready || post.status == .review {
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? "Salvar" : "Editar") {
                        if isEditing {
                            viewModel.updatePostContent(post, caption: editedCaption, hashtags: editedHashtags)
                        }
                        isEditing.toggle()
                    }
                }
            }
        }
        .alert("Aprovar Post?", isPresented: $showApproveAlert) {
            Button("Aprovar", role: .none) {
                viewModel.approvePost(post)
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("O post será agendado para publicação automática.")
        }
        .alert("Rejeitar Post?", isPresented: $showRejectAlert) {
            Button("Rejeitar", role: .destructive) {
                viewModel.rejectPost(post)
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Um novo conteúdo será gerado para substituir este post.")
        }
    }

    private var headerSection: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14)
                .fill(post.category.tintColor.opacity(0.12))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: post.category.icon)
                        .font(.title2)
                        .foregroundStyle(post.category.tintColor)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(post.category.displayName)
                    .font(.title3.weight(.bold))
                Text(post.scheduledFor.formatted(.dateTime.day().month(.wide).year().hour().minute()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusBadges: some View {
        HStack(spacing: 8) {
            Label(post.status.displayName, systemImage: post.status.icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(post.status.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(post.status.color.opacity(0.12))
                .clipShape(Capsule())

            if post.retryCount > 0 {
                Label("Tentativa \(post.retryCount)/3", systemImage: "arrow.clockwise")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.orange.opacity(0.12))
                    .clipShape(Capsule())
            }

            Spacer()
        }
    }

    private var imagePreview: some View {
        Group {
            if let imageUrl = post.imageUrl, let url = URL(string: imageUrl) {
                Color(.tertiarySystemGroupedBackground)
                    .frame(height: 260)
                    .overlay {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .allowsHitTesting(false)
                            } else if phase.error != nil {
                                imagePlaceholder
                            } else {
                                ProgressView()
                            }
                        }
                    }
                    .clipShape(.rect(cornerRadius: 16))
            } else {
                Color(.tertiarySystemGroupedBackground)
                    .frame(height: 220)
                    .overlay { imagePlaceholder }
                    .clipShape(.rect(cornerRadius: 16))
            }
        }
    }

    private var imagePlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Preview da Imagem")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let prompt = post.imagePrompt, !prompt.isEmpty {
                Text(prompt)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .lineLimit(2)
            }
        }
    }

    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legenda")
                .font(.headline)

            if isEditing {
                TextEditor(text: $editedCaption)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 12))
            } else {
                if post.caption.isEmpty {
                    Text("Legenda será gerada automaticamente")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 12))
                } else {
                    Text(post.caption)
                        .font(.subheadline)
                        .lineSpacing(4)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 12))
                }
            }
        }
    }

    private var hashtagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hashtags")
                .font(.headline)

            if isEditing {
                TextEditor(text: $editedHashtags)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 12))
            } else {
                if post.hashtags.isEmpty {
                    Text("Hashtags serão geradas automaticamente")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 12))
                } else {
                    Text(post.hashtags)
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 12))
                }
            }
        }
    }

    private var platformStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status por Plataforma")
                .font(.headline)

            VStack(spacing: 10) {
                PlatformStatusRow(platform: "Instagram", icon: "camera", status: post.instagramStatus, postID: post.instagramPostId, error: post.instagramError)
                Divider()
                PlatformStatusRow(platform: "Facebook", icon: "person.2", status: post.facebookStatus, postID: post.facebookPostId, error: post.facebookError)
                Divider()
                PlatformStatusRow(platform: "TikTok", icon: "music.note", status: post.tiktokStatus, postID: post.tiktokPostId, error: post.tiktokError)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Métricas")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                PostMetricCell(label: "IG Curtidas", value: post.instagramLikes, icon: "heart.fill", color: .pink)
                PostMetricCell(label: "IG Coment.", value: post.instagramComments, icon: "bubble.fill", color: .pink)
                PostMetricCell(label: "IG Alcance", value: post.instagramReach, icon: "eye.fill", color: .pink)
                PostMetricCell(label: "FB Curtidas", value: post.facebookLikes, icon: "hand.thumbsup.fill", color: .blue)
                PostMetricCell(label: "FB Coment.", value: post.facebookComments, icon: "bubble.fill", color: .blue)
                PostMetricCell(label: "FB Alcance", value: post.facebookReach, icon: "eye.fill", color: .blue)
                PostMetricCell(label: "TK Views", value: post.tiktokViews, icon: "play.fill", color: .primary)
                PostMetricCell(label: "TK Curtidas", value: post.tiktokLikes, icon: "heart.fill", color: .primary)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if post.status == .ready || post.status == .review {
                Button {
                    showApproveAlert = true
                } label: {
                    Label("Aprovar e Publicar", systemImage: "checkmark.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    showRejectAlert = true
                } label: {
                    Label("Rejeitar e Regenerar", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            if post.status == .failed {
                Button {
                    viewModel.retryPost(post)
                    dismiss()
                } label: {
                    Label("Tentar Novamente", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
    }
}

struct PlatformStatusRow: View {
    let platform: String
    let icon: String
    let status: PlatformStatus
    let postID: String?
    let error: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .frame(width: 24)
                .foregroundStyle(.secondary)

            Text(platform)
                .font(.subheadline)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: status.icon)
                        .font(.caption2)
                    Text(status.displayName)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(status.color)

                if let id = postID {
                    Text("ID: \(id)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                if let error {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

struct PostMetricCell: View {
    let label: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(NumberFormatter.compact(value))
                .font(.system(.subheadline, design: .rounded, weight: .bold))
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 10))
    }
}
