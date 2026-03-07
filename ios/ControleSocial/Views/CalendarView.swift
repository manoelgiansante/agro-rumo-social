import SwiftUI

struct CalendarView: View {
    let viewModel: DashboardViewModel
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var showingPostDetail: Post?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                monthNavigator
                dayHeaders
                calendarGrid
                selectedDatePosts
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Calendário")
        .sheet(item: $showingPostDetail) { post in
            NavigationStack {
                PostDetailView(post: post, viewModel: viewModel)
            }
        }
    }

    private var monthNavigator: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.35)) {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .symbolRenderingMode(.hierarchical)
            }

            Spacer()

            Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                .font(.title3.weight(.bold))

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35)) {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .padding(.horizontal, 8)
    }

    private var dayHeaders: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SÁB"], id: \.self) { day in
                Text(day)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        let days = daysInMonth()
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                if let date {
                    CalendarDayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        posts: viewModel.postsForDate(date)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDate = date
                        }
                    }
                    .sensoryFeedback(.selection, trigger: selectedDate)
                } else {
                    Color.clear
                        .frame(height: 54)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var selectedDatePosts: some View {
        let posts = viewModel.postsForDate(selectedDate)
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(selectedDate.formatted(.dateTime.day().month(.wide)))
                        .font(.headline)
                }
                Spacer()
                Text("\(posts.count) post\(posts.count != 1 ? "s" : "")")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Capsule())
            }

            if posts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Nenhum post agendado")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(posts) { post in
                    Button {
                        showingPostDetail = post
                    } label: {
                        CalendarPostCard(post: post)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private func daysInMonth() -> [Date?] {
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let weekday = calendar.component(.weekday, from: firstDay)
        let leadingSpaces = weekday - 1

        var days: [Date?] = Array(repeating: nil, count: leadingSpaces)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }
}

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let posts: [Post]

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline.weight(isToday || isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? .white : (isToday ? .green : .primary))

            if !posts.isEmpty {
                HStack(spacing: 2) {
                    ForEach(posts.prefix(3)) { post in
                        Circle()
                            .fill(isSelected ? .white.opacity(0.8) : post.status.color)
                            .frame(width: 5, height: 5)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.green : (isToday ? Color.green.opacity(0.1) : Color.clear))
        )
    }
}

struct CalendarPostCard: View {
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
                Text(post.category.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Image(systemName: post.status.icon)
                        .font(.caption2)
                    Text(post.status.displayName)
                        .font(.caption)
                }
                .foregroundStyle(post.status.color)

                if !post.caption.isEmpty {
                    Text(String(post.caption.prefix(60)) + "...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(post.scheduledFor.formatted(.dateTime.hour().minute()))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 3) {
                    Image(systemName: post.instagramStatus.icon)
                        .foregroundStyle(post.instagramStatus.color)
                    Image(systemName: post.facebookStatus.icon)
                        .foregroundStyle(post.facebookStatus.color)
                    Image(systemName: post.tiktokStatus.icon)
                        .foregroundStyle(post.tiktokStatus.color)
                }
                .font(.system(size: 10))
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }
}
