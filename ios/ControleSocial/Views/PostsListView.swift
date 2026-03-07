import SwiftUI

struct PostsListView: View {
    let viewModel: DashboardViewModel
    @State private var selectedStatus: PostStatus?
    @State private var searchText: String = ""
    @State private var showingPostDetail: Post?

    private var filteredPosts: [Post] {
        var result = viewModel.posts
        if let status = selectedStatus {
            result = result.filter { $0.status == status }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.category.displayName.localizedStandardContains(searchText) ||
                $0.caption.localizedStandardContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        List {
            filterSection
            ForEach(filteredPosts) { post in
                Button {
                    showingPostDetail = post
                } label: {
                    PostListRow(post: post)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
        .navigationTitle("Posts")
        .searchable(text: $searchText, prompt: "Buscar posts...")
        .overlay {
            if filteredPosts.isEmpty {
                ContentUnavailableView("Nenhum post encontrado", systemImage: "doc.text.magnifyingglass", description: Text("Tente alterar os filtros ou busca"))
            }
        }
        .sheet(item: $showingPostDetail) { post in
            NavigationStack {
                PostDetailView(post: post, viewModel: viewModel)
            }
        }
    }

    private var filterSection: some View {
        Section {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    FilterChip(title: "Todos", isSelected: selectedStatus == nil) {
                        selectedStatus = nil
                    }
                    ForEach([PostStatus.published, .ready, .pending, .failed], id: \.self) { status in
                        FilterChip(title: status.displayName, isSelected: selectedStatus == status, color: status.color) {
                            selectedStatus = status
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 0))
        }
        .listRowBackground(Color.clear)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .green
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
                .foregroundStyle(isSelected ? color : .secondary)
                .clipShape(Capsule())
        }
    }
}

struct PostListRow: View {
    let post: Post

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(post.category.tintColor.opacity(0.12))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: post.category.icon)
                        .font(.title3)
                        .foregroundStyle(post.category.tintColor)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(post.category.displayName)
                        .font(.subheadline.weight(.semibold))

                    Label(post.status.displayName, systemImage: post.status.icon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(post.status.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(post.status.color.opacity(0.1))
                        .clipShape(Capsule())
                }

                if !post.caption.isEmpty {
                    Text(post.caption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    Label(post.scheduledFor.formatted(.dateTime.day().month(.abbreviated).hour().minute()), systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if post.status == .published {
                        Label("\(post.totalEngagement)", systemImage: "heart")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
