import Foundation

nonisolated enum SocialPlatform: String, Codable, Sendable, CaseIterable {
    case instagram
    case facebook
    case tiktok

    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .facebook: return "Facebook"
        case .tiktok: return "TikTok"
        }
    }

    var icon: String {
        switch self {
        case .instagram: return "camera"
        case .facebook: return "person.2"
        case .tiktok: return "music.note"
        }
    }

    var brandColor: String {
        switch self {
        case .instagram: return "pink"
        case .facebook: return "blue"
        case .tiktok: return "primary"
        }
    }
}

nonisolated struct SocialAccount: Identifiable, Codable, Sendable {
    let id: String
    let platform: SocialPlatform
    let accountName: String
    let accountId: String
    var isActive: Bool
    var tokenExpiresAt: Date?
    var pageId: String?

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        platform = try container.decode(SocialPlatform.self, forKey: .platform)
        accountName = try container.decodeIfPresent(String.self, forKey: .accountName) ?? ""
        accountId = try container.decodeIfPresent(String.self, forKey: .accountId) ?? ""
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        tokenExpiresAt = try container.decodeIfPresent(Date.self, forKey: .tokenExpiresAt)
        pageId = try container.decodeIfPresent(String.self, forKey: .pageId)
    }

    init(id: String, platform: SocialPlatform, accountName: String, accountId: String, isActive: Bool, tokenExpiresAt: Date? = nil, pageId: String? = nil) {
        self.id = id
        self.platform = platform
        self.accountName = accountName
        self.accountId = accountId
        self.isActive = isActive
        self.tokenExpiresAt = tokenExpiresAt
        self.pageId = pageId
    }
}
