import Foundation

nonisolated enum PostStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case generating
    case ready
    case review
    case publishing
    case published
    case failed
    case rejected
}

nonisolated enum PlatformStatus: String, Codable, Sendable {
    case pending
    case published
    case failed
    case skipped
}

nonisolated enum PostCategory: String, Codable, Sendable, CaseIterable {
    case dicaManutencao = "DICA_MANUTENCAO"
    case curiosidadeAgro = "CURIOSIDADE_AGRO"
    case economiaCombustivel = "ECONOMIA_COMBUSTIVEL"
    case gestaoFazenda = "GESTAO_FAZENDA"
    case pecuaria = "PECUARIA"
    case motivacionalAgro = "MOTIVACIONAL_AGRO"
    case appShowcase = "APP_SHOWCASE"

    var displayName: String {
        switch self {
        case .dicaManutencao: return "Dica Manutenção"
        case .curiosidadeAgro: return "Curiosidade Agro"
        case .economiaCombustivel: return "Economia Combustível"
        case .gestaoFazenda: return "Gestão Fazenda"
        case .pecuaria: return "Pecuária"
        case .motivacionalAgro: return "Motivacional Agro"
        case .appShowcase: return "App Showcase"
        }
    }

    var icon: String {
        switch self {
        case .dicaManutencao: return "wrench.and.screwdriver"
        case .curiosidadeAgro: return "leaf"
        case .economiaCombustivel: return "fuelpump"
        case .gestaoFazenda: return "chart.bar"
        case .pecuaria: return "hare"
        case .motivacionalAgro: return "sun.max"
        case .appShowcase: return "iphone"
        }
    }
}

nonisolated struct Post: Identifiable, Codable, Sendable, Hashable {
    let id: String
    var category: PostCategory
    var caption: String
    var hashtags: String
    var imageUrl: String?
    var imagePrompt: String?
    var scheduledFor: Date
    var publishedAt: Date?
    var status: PostStatus

    var instagramPostId: String?
    var instagramStatus: PlatformStatus
    var instagramError: String?

    var facebookPostId: String?
    var facebookStatus: PlatformStatus
    var facebookError: String?

    var tiktokPostId: String?
    var tiktokStatus: PlatformStatus
    var tiktokError: String?

    var instagramLikes: Int
    var instagramComments: Int
    var instagramReach: Int
    var facebookLikes: Int
    var facebookComments: Int
    var facebookReach: Int
    var tiktokViews: Int
    var tiktokLikes: Int

    var retryCount: Int
    var createdAt: Date

    var totalEngagement: Int {
        instagramLikes + instagramComments + facebookLikes + facebookComments + tiktokLikes
    }

    var totalReach: Int {
        instagramReach + facebookReach + tiktokViews
    }

    var publishedPlatformCount: Int {
        var count = 0
        if instagramStatus == .published { count += 1 }
        if facebookStatus == .published { count += 1 }
        if tiktokStatus == .published { count += 1 }
        return count
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        category = try container.decode(PostCategory.self, forKey: .category)
        caption = try container.decodeIfPresent(String.self, forKey: .caption) ?? ""
        hashtags = try container.decodeIfPresent(String.self, forKey: .hashtags) ?? ""
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        imagePrompt = try container.decodeIfPresent(String.self, forKey: .imagePrompt)
        scheduledFor = try container.decode(Date.self, forKey: .scheduledFor)
        publishedAt = try container.decodeIfPresent(Date.self, forKey: .publishedAt)
        status = try container.decodeIfPresent(PostStatus.self, forKey: .status) ?? .pending

        instagramPostId = try container.decodeIfPresent(String.self, forKey: .instagramPostId)
        instagramStatus = try container.decodeIfPresent(PlatformStatus.self, forKey: .instagramStatus) ?? .pending
        instagramError = try container.decodeIfPresent(String.self, forKey: .instagramError)

        facebookPostId = try container.decodeIfPresent(String.self, forKey: .facebookPostId)
        facebookStatus = try container.decodeIfPresent(PlatformStatus.self, forKey: .facebookStatus) ?? .pending
        facebookError = try container.decodeIfPresent(String.self, forKey: .facebookError)

        tiktokPostId = try container.decodeIfPresent(String.self, forKey: .tiktokPostId)
        tiktokStatus = try container.decodeIfPresent(PlatformStatus.self, forKey: .tiktokStatus) ?? .pending
        tiktokError = try container.decodeIfPresent(String.self, forKey: .tiktokError)

        instagramLikes = try container.decodeIfPresent(Int.self, forKey: .instagramLikes) ?? 0
        instagramComments = try container.decodeIfPresent(Int.self, forKey: .instagramComments) ?? 0
        instagramReach = try container.decodeIfPresent(Int.self, forKey: .instagramReach) ?? 0
        facebookLikes = try container.decodeIfPresent(Int.self, forKey: .facebookLikes) ?? 0
        facebookComments = try container.decodeIfPresent(Int.self, forKey: .facebookComments) ?? 0
        facebookReach = try container.decodeIfPresent(Int.self, forKey: .facebookReach) ?? 0
        tiktokViews = try container.decodeIfPresent(Int.self, forKey: .tiktokViews) ?? 0
        tiktokLikes = try container.decodeIfPresent(Int.self, forKey: .tiktokLikes) ?? 0

        retryCount = try container.decodeIfPresent(Int.self, forKey: .retryCount) ?? 0
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    init(
        id: String, category: PostCategory, caption: String, hashtags: String,
        imageUrl: String?, imagePrompt: String?, scheduledFor: Date,
        publishedAt: Date?, status: PostStatus,
        instagramPostId: String?, instagramStatus: PlatformStatus, instagramError: String?,
        facebookPostId: String?, facebookStatus: PlatformStatus, facebookError: String?,
        tiktokPostId: String?, tiktokStatus: PlatformStatus, tiktokError: String?,
        instagramLikes: Int, instagramComments: Int, instagramReach: Int,
        facebookLikes: Int, facebookComments: Int, facebookReach: Int,
        tiktokViews: Int, tiktokLikes: Int,
        retryCount: Int, createdAt: Date
    ) {
        self.id = id
        self.category = category
        self.caption = caption
        self.hashtags = hashtags
        self.imageUrl = imageUrl
        self.imagePrompt = imagePrompt
        self.scheduledFor = scheduledFor
        self.publishedAt = publishedAt
        self.status = status
        self.instagramPostId = instagramPostId
        self.instagramStatus = instagramStatus
        self.instagramError = instagramError
        self.facebookPostId = facebookPostId
        self.facebookStatus = facebookStatus
        self.facebookError = facebookError
        self.tiktokPostId = tiktokPostId
        self.tiktokStatus = tiktokStatus
        self.tiktokError = tiktokError
        self.instagramLikes = instagramLikes
        self.instagramComments = instagramComments
        self.instagramReach = instagramReach
        self.facebookLikes = facebookLikes
        self.facebookComments = facebookComments
        self.facebookReach = facebookReach
        self.tiktokViews = tiktokViews
        self.tiktokLikes = tiktokLikes
        self.retryCount = retryCount
        self.createdAt = createdAt
    }
}
