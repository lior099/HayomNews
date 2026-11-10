import Foundation
import SwiftUI

@MainActor
final class NewsStore: ObservableObject {
    @Published var stories: [NewsStory] = []
    @Published var daily: [NewsStory] = []
    @Published var loading = false
    @Published var errorMessage: String?
    @Published var feedErrors: [String] = []
    @Published var aiEnabled = false
    @Published var updatedAt: Date?
    @Published var savedIDs: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "savedStories") ?? []) {
        didSet { UserDefaults.standard.set(Array(savedIDs), forKey: "savedStories") }
    }

    // Set this to your reachable HTTPS backend URL before running on a physical iPhone.
    // The iOS Simulator can use http://localhost:8000 for local development (ATS exception needed).
    static let apiBase = "https://YOUR-SERVER.example.com"

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func refresh() async {
        loading = true
        defer { loading = false }
        do {
            guard let url = URL(string: Self.apiBase + "/news"),
                  let dailyURL = URL(string: Self.apiBase + "/daily") else {
                throw URLError(.badURL)
            }
            async let newsTask = URLSession.shared.data(from: url)
            async let dailyTask = URLSession.shared.data(from: dailyURL)
            let ((newsData, newsResponse), (dailyData, dailyResponse)) = try await (newsTask, dailyTask)
            guard (newsResponse as? HTTPURLResponse)?.statusCode == 200,
                  (dailyResponse as? HTTPURLResponse)?.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            let latest = try decoder.decode(NewsResponse.self, from: newsData)
            let digest = try decoder.decode(NewsResponse.self, from: dailyData)
            stories = latest.stories
            daily = digest.stories
            feedErrors = latest.feedErrors
            aiEnabled = latest.aiEnabled
            updatedAt = Date()
            errorMessage = nil
        } catch {
            errorMessage = "לא ניתן לטעון חדשות. יש לבדוק את כתובת השרת ואת החיבור לרשת."
        }
    }

    func toggleSaved(_ story: NewsStory) {
        if savedIDs.contains(story.id) { savedIDs.remove(story.id) }
        else { savedIDs.insert(story.id) }
    }
}
