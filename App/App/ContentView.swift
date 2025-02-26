import FeatureChat
import LocalData
import SwiftUI

struct ContentView: View {
    var body: some View {
        ChatEntryView()
            .modelContainer(for: [
                MessageRootData.self,
                MessageContentData.self,
                MessageMember.self,
            ])
    }
}

#Preview {
    ContentView()
}
