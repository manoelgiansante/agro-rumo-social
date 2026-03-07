import Foundation

nonisolated struct SupabaseResponse<T: Decodable & Sendable>: Sendable {
    let data: T?
    let error: String?
}

nonisolated enum SupabaseError: Error, Sendable {
    case invalidURL
    case networkError(String)
    case decodingError(String)
    case apiError(String)
}

actor SupabaseService {
    static let shared = SupabaseService()

    private let baseURL: String
    private let anonKey: String
    private let serviceRoleKey: String

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let fmtFrac = ISO8601DateFormatter()
            fmtFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fmtFrac.date(from: string) { return date }
            let fmtBasic = ISO8601DateFormatter()
            fmtBasic.formatOptions = [.withInternetDateTime]
            if let date = fmtBasic.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try container.encode(fmt.string(from: date))
        }
        return e
    }()

    private init() {
        let url = MainActor.assumeIsolated { Config.SUPABASE_URL }
        let anon = MainActor.assumeIsolated { Config.SUPABASE_ANON_KEY }
        let service = MainActor.assumeIsolated { Config.SUPABASE_SERVICE_ROLE_KEY }
        self.baseURL = url.isEmpty ? "https://jxcnfyeemdltdfqtgbcl.supabase.co" : url
        self.anonKey = anon.isEmpty ? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4Y25meWVlbWRsdGRmcXRnYmNsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1MDQwNTksImV4cCI6MjA4NDA4MDA1OX0.MEqgaUHb0cDVoDrXY6rc1F6YJLxzbpNiks-SFRCg2go" : anon
        self.serviceRoleKey = service.isEmpty ? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4Y25meWVlbWRsdGRmcXRnYmNsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2ODUwNDA1OSwiZXhwIjoyMDg0MDgwMDU5fQ.kSZ0Lm4UED4zDtdvESjC3Qtb-8jgpG_Hinir5Hp22pY" : service
    }

    private func userToken() -> String? {
        UserDefaults.standard.string(forKey: "cs_access_token")
    }

    private func makeRequest(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        query: [String: String] = [:],
        useServiceRole: Bool = false
    ) async throws -> Data {
        var urlString = "\(baseURL)/rest/v1/\(path)"
        if !query.isEmpty {
            let queryString = query.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            urlString += "?\(queryString)"
        }

        guard let url = URL(string: urlString) else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        if useServiceRole {
            request.setValue("Bearer \(serviceRoleKey)", forHTTPHeaderField: "Authorization")
        } else if let token = userToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }

        if method == "POST" || method == "PATCH" {
            request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        }

        if let body {
            request.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.networkError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SupabaseError.apiError("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        return data
    }

    func fetchPosts(limit: Int = 35) async throws -> [Post] {
        let data = try await makeRequest(
            path: "posts",
            query: [
                "select": "*",
                "order": "scheduled_for.desc",
                "limit": "\(limit)"
            ]
        )
        return try decoder.decode([Post].self, from: data)
    }

    func fetchAccounts() async throws -> [SocialAccount] {
        let data = try await makeRequest(
            path: "social_accounts",
            query: ["select": "*", "order": "platform.asc"]
        )
        return try decoder.decode([SocialAccount].self, from: data)
    }

    func fetchCalendar() async throws -> [ContentCalendarEntry] {
        let data = try await makeRequest(
            path: "content_calendar",
            query: ["select": "*", "order": "day_of_week.asc"]
        )
        return try decoder.decode([ContentCalendarEntry].self, from: data)
    }

    func updatePostStatus(postId: String, status: PostStatus) async throws {
        let body = try encoder.encode(["status": status.rawValue])
        _ = try await makeRequest(
            path: "posts",
            method: "PATCH",
            body: body,
            query: ["id": "eq.\(postId)"]
        )
    }

    func updatePost(postId: String, caption: String, hashtags: String) async throws {
        let payload: [String: String] = ["caption": caption, "hashtags": hashtags]
        let body = try encoder.encode(payload)
        _ = try await makeRequest(
            path: "posts",
            method: "PATCH",
            body: body,
            query: ["id": "eq.\(postId)"]
        )
    }

    func saveAccount(_ account: SocialAccountPayload) async throws -> [SocialAccount] {
        let body = try encoder.encode(account)
        let data = try await makeRequest(
            path: "social_accounts",
            method: "POST",
            body: body,
            useServiceRole: true
        )
        return try decoder.decode([SocialAccount].self, from: data)
    }

    func deleteAccount(id: String) async throws {
        _ = try await makeRequest(
            path: "social_accounts",
            method: "DELETE",
            query: ["id": "eq.\(id)"],
            useServiceRole: true
        )
    }

    func updateAccountToken(id: String, accessToken: String, expiresAt: Date?) async throws {
        var payload: [String: String] = ["access_token": accessToken]
        if let expiresAt {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            payload["token_expires_at"] = formatter.string(from: expiresAt)
        }
        let body = try encoder.encode(payload)
        _ = try await makeRequest(
            path: "social_accounts",
            method: "PATCH",
            body: body,
            query: ["id": "eq.\(id)"],
            useServiceRole: true
        )
    }

    func callEdgeFunction(name: String, body: [String: Any]? = nil) async throws -> Data {
        let urlString = "\(baseURL)/functions/v1/\(name)"
        guard let url = URL(string: urlString) else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(serviceRoleKey)", forHTTPHeaderField: "Authorization")

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
            throw SupabaseError.apiError("Edge function failed: \(errorBody)")
        }

        return data
    }

    func fetchPostMetrics() async throws -> PostMetricsAggregation {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let dateString = ISO8601DateFormatter().string(from: thirtyDaysAgo)
        let data = try await makeRequest(
            path: "posts",
            query: [
                "select": "instagram_likes,instagram_comments,instagram_reach,facebook_likes,facebook_comments,facebook_reach,tiktok_views,tiktok_likes,status",
                "scheduled_for": "gte.\(dateString)",
                "order": "scheduled_for.desc"
            ]
        )
        let posts = try decoder.decode([PostMetricRow].self, from: data)
        return PostMetricsAggregation.from(posts)
    }

    func createPost(category: String, caption: String, hashtags: String, scheduledFor: Date, status: String) async throws -> [Post] {
        let payload: [String: Any] = [
            "category": category,
            "caption": caption,
            "hashtags": hashtags,
            "scheduled_for": ISO8601DateFormatter().string(from: scheduledFor),
            "status": status,
            "instagram_status": "pending",
            "facebook_status": "pending",
            "tiktok_status": "pending"
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let data = try await makeRequest(
            path: "posts",
            method: "POST",
            body: body
        )
        return try decoder.decode([Post].self, from: data)
    }
}

nonisolated struct SocialAccountPayload: Codable, Sendable {
    let platform: String
    let accountName: String
    let accountId: String
    let accessToken: String
    let refreshToken: String?
    let tokenExpiresAt: String?
    let pageId: String?
    let isActive: Bool
}

nonisolated struct PostMetricRow: Codable, Sendable {
    let instagramLikes: Int?
    let instagramComments: Int?
    let instagramReach: Int?
    let facebookLikes: Int?
    let facebookComments: Int?
    let facebookReach: Int?
    let tiktokViews: Int?
    let tiktokLikes: Int?
    let status: String?
}

nonisolated struct PostMetricsAggregation: Sendable {
    let instagramReach: Int
    let instagramLikes: Int
    let instagramComments: Int
    let facebookReach: Int
    let facebookLikes: Int
    let facebookComments: Int
    let tiktokViews: Int
    let tiktokLikes: Int
    let totalPosts: Int
    let publishedPosts: Int
    let failedPosts: Int

    static func from(_ rows: [PostMetricRow]) -> PostMetricsAggregation {
        var igReach = 0, igLikes = 0, igComments = 0
        var fbReach = 0, fbLikes = 0, fbComments = 0
        var tkViews = 0, tkLikes = 0
        for row in rows {
            igReach += row.instagramReach ?? 0
            igLikes += row.instagramLikes ?? 0
            igComments += row.instagramComments ?? 0
            fbReach += row.facebookReach ?? 0
            fbLikes += row.facebookLikes ?? 0
            fbComments += row.facebookComments ?? 0
            tkViews += row.tiktokViews ?? 0
            tkLikes += row.tiktokLikes ?? 0
        }
        return PostMetricsAggregation(
            instagramReach: igReach, instagramLikes: igLikes, instagramComments: igComments,
            facebookReach: fbReach, facebookLikes: fbLikes, facebookComments: fbComments,
            tiktokViews: tkViews, tiktokLikes: tkLikes,
            totalPosts: rows.count,
            publishedPosts: rows.filter { $0.status == "published" }.count,
            failedPosts: rows.filter { $0.status == "failed" }.count
        )
    }
}
