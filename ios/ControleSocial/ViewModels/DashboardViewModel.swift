import Foundation
import SwiftUI

@Observable
@MainActor
class DashboardViewModel {
    var posts: [Post] = []
    var accounts: [SocialAccount] = []
    var metrics: MetricsSummary?
    var calendarEntries: [ContentCalendarEntry] = []
    var isLoading = false
    var errorMessage: String?
    var selectedPost: Post?
    var useMockData = false

    var todaysPosts: [Post] {
        let calendar = Calendar.current
        return posts.filter { calendar.isDateInToday($0.scheduledFor) }
    }

    var pendingReviewPosts: [Post] {
        posts.filter { $0.status == .ready || $0.status == .review }
    }

    var recentPublishedPosts: [Post] {
        posts.filter { $0.status == .published }
            .prefix(5)
            .map { $0 }
    }

    var failedPosts: [Post] {
        posts.filter { $0.status == .failed }
    }

    var publishedCount: Int {
        posts.filter { $0.status == .published }.count
    }

    var weeklyPosts: [Post] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        return posts.filter { $0.scheduledFor >= startOfWeek && $0.scheduledFor < endOfWeek }
            .sorted { $0.scheduledFor < $1.scheduledFor }
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil

        if Config.SUPABASE_URL.isEmpty || useMockData {
            posts = MockDataService.generatePosts()
            accounts = MockDataService.generateAccounts()
            metrics = MockDataService.generateMetrics()
            calendarEntries = MockDataService.generateCalendar()
            isLoading = false
            return
        }

        do {
            async let postsTask = SupabaseService.shared.fetchPosts()
            async let accountsTask = SupabaseService.shared.fetchAccounts()
            async let calendarTask = SupabaseService.shared.fetchCalendar()
            async let metricsTask = SupabaseService.shared.fetchPostMetrics()

            let (fetchedPosts, fetchedAccounts, fetchedCalendar, fetchedMetrics) = try await (postsTask, accountsTask, calendarTask, metricsTask)

            posts = fetchedPosts
            accounts = fetchedAccounts
            calendarEntries = fetchedCalendar
            metrics = MetricsSummary(
                instagramReach: fetchedMetrics.instagramReach,
                instagramReachChange: 0,
                instagramLikes: fetchedMetrics.instagramLikes,
                instagramComments: fetchedMetrics.instagramComments,
                facebookReach: fetchedMetrics.facebookReach,
                facebookReachChange: 0,
                facebookLikes: fetchedMetrics.facebookLikes,
                facebookComments: fetchedMetrics.facebookComments,
                tiktokViews: fetchedMetrics.tiktokViews,
                tiktokViewsChange: 0,
                tiktokLikes: fetchedMetrics.tiktokLikes,
                totalPosts: fetchedMetrics.totalPosts,
                publishedPosts: fetchedMetrics.publishedPosts,
                failedPosts: fetchedMetrics.failedPosts,
                bestHour: "07:00 - 08:00",
                bestCategory: "—"
            )

            if posts.isEmpty {
                useMockData = true
                posts = MockDataService.generatePosts()
                accounts = MockDataService.generateAccounts()
                metrics = MockDataService.generateMetrics()
                calendarEntries = MockDataService.generateCalendar()
            }
        } catch {
            errorMessage = error.localizedDescription
            useMockData = true
            posts = MockDataService.generatePosts()
            accounts = MockDataService.generateAccounts()
            metrics = MockDataService.generateMetrics()
            calendarEntries = MockDataService.generateCalendar()
        }

        isLoading = false
    }

    func approvePost(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].status = .ready
        Task {
            try? await SupabaseService.shared.updatePostStatus(postId: post.id, status: .ready)
        }
    }

    func rejectPost(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].status = .rejected
        Task {
            try? await SupabaseService.shared.updatePostStatus(postId: post.id, status: .rejected)
        }
    }

    func retryPost(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].status = .publishing
        posts[index].retryCount += 1
        Task {
            try? await SupabaseService.shared.updatePostStatus(postId: post.id, status: .publishing)
        }
    }

    func updatePostContent(_ post: Post, caption: String, hashtags: String) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].caption = caption
        posts[index].hashtags = hashtags
        Task {
            try? await SupabaseService.shared.updatePost(postId: post.id, caption: caption, hashtags: hashtags)
        }
    }

    func generateContent() async {
        do {
            _ = try await SupabaseService.shared.callEdgeFunction(name: "generate-content")
            await loadData()
        } catch {
            errorMessage = "Erro ao gerar conteúdo: \(error.localizedDescription)"
        }
    }

    func publishNow() async {
        do {
            _ = try await SupabaseService.shared.callEdgeFunction(name: "publish-content")
            await loadData()
        } catch {
            errorMessage = "Erro ao publicar: \(error.localizedDescription)"
        }
    }

    func addAccount(_ account: SocialAccount) {
        if let index = accounts.firstIndex(where: { $0.platform == account.platform }) {
            accounts[index] = account
        } else {
            accounts.append(account)
        }
    }

    func removeAccount(_ account: SocialAccount) {
        accounts.removeAll { $0.id == account.id }
        Task {
            try? await SupabaseService.shared.deleteAccount(id: account.id)
        }
    }

    func postsForDate(_ date: Date) -> [Post] {
        let calendar = Calendar.current
        return posts.filter { calendar.isDate($0.scheduledFor, inSameDayAs: date) }
    }
}
