import SwiftUI
import LocalData
import FeatureChat

struct ContentView: View {
    var body: some View {
        ChatListView()
            .modelContainer(for: [
                MessageRootData.self,
                MessageContentData.self
            ])
    }
}

#Preview {
    ContentView()
}
