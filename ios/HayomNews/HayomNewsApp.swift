import SwiftUI

@main
struct HayomNewsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}
