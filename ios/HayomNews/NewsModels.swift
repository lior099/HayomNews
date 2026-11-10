import Foundation

struct Article: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let source: String
    let url: String
    let publishedAt: Date
    let region: String
    let category: String

    enum CodingKeys: String, CodingKey {
        case id, title, summary, source, url, region, category
        case publishedAt = "published_at"
    }
}

struct NewsStory: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let category: String
    let region: String
    let publishedAt: Date
    let sources: [String]
    let articles: [Article]

    enum CodingKeys: String, CodingKey {
        case id, title, summary, category, region, sources, articles
        case publishedAt = "published_at"
    }
}

struct NewsResponse: Codable {
    let generatedAt: Date
    let stories: [NewsStory]
    let feedErrors: [String]
    let aiEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case stories
        case feedErrors = "feed_errors"
        case aiEnabled = "ai_enabled"
    }
}
