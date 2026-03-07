import Foundation

struct MetricsSummary {
    var instagramReach: Int
    var instagramReachChange: Double
    var instagramLikes: Int
    var instagramComments: Int

    var facebookReach: Int
    var facebookReachChange: Double
    var facebookLikes: Int
    var facebookComments: Int

    var tiktokViews: Int
    var tiktokViewsChange: Double
    var tiktokLikes: Int

    var totalPosts: Int
    var publishedPosts: Int
    var failedPosts: Int

    var bestHour: String
    var bestCategory: String
}
