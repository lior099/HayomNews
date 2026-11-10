import SwiftUI

private let ink = Color(red: 0.09, green: 0.16, blue: 0.25)
private let accent = Color(red: 0.10, green: 0.37, blue: 0.73)

struct ContentView: View {
    @StateObject private var store = NewsStore()
    @State private var selectedRegion = "הכל"
    @State private var selectedCategory = "הכל"
    @State private var selectedTab = 0

    private let categories = ["הכל", "ביטחון", "פוליטיקה", "כלכלה", "טכנולוגיה", "מדע", "כללי"]

    private var filtered: [NewsStory] {
        store.stories.filter { story in
            (selectedRegion == "הכל" || story.region == selectedRegion) &&
            (selectedCategory == "הכל" || story.category == selectedCategory) &&
            (selectedTab != 2 || store.savedIDs.contains(story.id))
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { mainView }
                .tabItem { Label("ראשי", systemImage: "house.fill") }.tag(0)
            NavigationStack { feedView }
                .tabItem { Label("עדכונים", systemImage: "bolt.fill") }.tag(1)
            NavigationStack { feedView }
                .tabItem { Label("שמורים", systemImage: "bookmark.fill") }.tag(2)
        }
        .tint(accent)
        .task { await store.refresh() }
    }

    private var mainView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if let error = store.errorMessage { errorView(error) }
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("סיכום היום", systemImage: "sparkles").font(.title2.bold())
                        Spacer()
                        Text(store.aiEnabled ? "AI" : "RSS")
                            .font(.caption.bold()).padding(.horizontal, 9).padding(.vertical, 5)
                            .background(accent.opacity(0.1), in: Capsule())
                    }
                    Text("האירועים המרכזיים בישראל ובעולם")
                        .foregroundStyle(.secondary)
                    if store.daily.isEmpty {
                        Text("אין עדיין דיווחים מהיום. משוך לרענון או בדוק את חיבור השרת.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(store.daily.prefix(8)) { story in
                        NavigationLink(value: story) { storyRow(story) }
                            .buttonStyle(.plain)
                        Divider()
                    }
                }
                .padding(18)
                .background(.white, in: RoundedRectangle(cornerRadius: 20))
                HStack {
                    Text("עדכונים אחרונים").font(.title2.bold())
                    Spacer()
                    Button("הצג הכל") { selectedTab = 1 }
                }
                ForEach(store.stories.prefix(8)) { story in
                    NavigationLink(value: story) { storyRow(story) }
                        .buttonStyle(.plain)
                        .padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 15))
                }
                if !store.feedErrors.isEmpty {
                    Text("חלק ממקורות החדשות אינם זמינים כרגע.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .refreshable { await store.refresh() }
        .navigationDestination(for: NewsStory.self) { story in
            StoryDetailView(story: story, store: store)
        }
    }

    private var feedView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                if let error = store.errorMessage { errorView(error) }
                Picker("אזור", selection: $selectedRegion) {
                    ForEach(["הכל", "ישראל", "עולם"], id: \.self) { Text($0) }
                }.pickerStyle(.segmented)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(categories, id: \.self) { category in
                            Button(category) { selectedCategory = category }
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 13).padding(.vertical, 9)
                                .background(selectedCategory == category ? accent : Color.white, in: Capsule())
                                .foregroundStyle(selectedCategory == category ? .white : ink)
                        }
                    }
                }
                if filtered.isEmpty {
                    ContentUnavailableView("אין ידיעות להצגה", systemImage: "newspaper")
                }
                ForEach(filtered) { story in
                    NavigationLink(value: story) { storyRow(story) }
                        .buttonStyle(.plain)
                        .padding(15)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16))
                }
            }.padding()
        }
        .background(Color(.systemGroupedBackground))
        .refreshable { await store.refresh() }
        .navigationDestination(for: NewsStory.self) { story in
            StoryDetailView(story: story, store: store)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("היום.").font(.system(size: 40, weight: .black, design: .rounded)).foregroundStyle(ink)
                Text("כל מה שחשוב לדעת, במקום אחד").font(.subheadline).foregroundStyle(.secondary)
                if let updated = store.updatedAt {
                    Text("עודכן \(updated.formatted(date: .omitted, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if store.loading { ProgressView() }
            else {
                Button { Task { await store.refresh() } } label: {
                    Image(systemName: "arrow.clockwise").font(.title3)
                }.accessibilityLabel("רענון חדשות")
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        Label(message, systemImage: "wifi.exclamationmark")
            .font(.subheadline).foregroundStyle(.orange)
            .padding().frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func storyRow(_ story: NewsStory) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(story.category).font(.caption.bold()).foregroundStyle(accent)
                Text("·").foregroundStyle(.secondary)
                Text(story.region).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(story.publishedAt, style: .time).font(.caption).foregroundStyle(.secondary)
            }
            Text(story.title).font(.headline).foregroundStyle(ink).multilineTextAlignment(.leading)
            Text(story.summary).font(.subheadline).foregroundStyle(.secondary)
                .lineLimit(3).multilineTextAlignment(.leading)
            Label("\(story.sources.count) מקורות · \(story.sources.joined(separator: ", "))", systemImage: "newspaper")
                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
    }
}

private struct StoryDetailView: View {
    let story: NewsStory
    @ObservedObject var store: NewsStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(story.category + " · " + story.region)
                    .font(.subheadline.bold()).foregroundStyle(accent)
                Text(story.title).font(.largeTitle.bold()).foregroundStyle(ink)
                Text(story.summary).font(.body).textSelection(.enabled)
                Text("הסיכום מבוסס על כותרות ותקצירי RSS. יש לעיין במקורות כדי לאמת פרטים.")
                    .font(.caption).foregroundStyle(.secondary)
                Button {
                    store.toggleSaved(story)
                } label: {
                    Label(store.savedIDs.contains(story.id) ? "הסר משמורים" : "שמור ידיעה",
                          systemImage: store.savedIDs.contains(story.id) ? "bookmark.fill" : "bookmark")
                }
                Divider()
                Text("מקורות ודיווחים").font(.title2.bold())
                ForEach(story.articles) { article in
                    if let url = URL(string: article.url),
                       ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                        Link(destination: url) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(article.source).font(.caption.bold()).foregroundStyle(accent)
                                    Text(article.title).font(.body).foregroundStyle(ink)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.left.square")
                            }.padding().background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }.padding()
        }
        .navigationTitle("פרטי הידיעה")
        .navigationBarTitleDisplayMode(.inline)
    }
}
