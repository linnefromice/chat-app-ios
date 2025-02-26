import FeatureChat
import LocalData
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ChatListView()
        }
        .modelContainer(for: [
            MessageRootData.self,
            MessageContentData.self,
        ])
    }
}

#Preview {
    ContentView()
}
