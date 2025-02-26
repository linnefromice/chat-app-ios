import SwiftUI
import SwiftData
import LocalData

public struct ChatListView: View {
    @Query private var chatRooms: [MessageRootData]
    @Environment(\.modelContext) private var modelContext
    
    public init() {
        // デフォルトのクエリ設定
        _chatRooms = Query(sort: \MessageRootData.lastMessageDate, order: .reverse)
    }
    
    public var body: some View {
        List(chatRooms) { room in
            VStack(alignment: .leading, spacing: 4) {
                Text(room.name)
                    .font(.headline)
                Text(room.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(room.lastMessageDate, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("チャット")
        .onAppear {
            if chatRooms.isEmpty {
                addSampleData()
            }
        }
    }
    
    private func addSampleData() {
        let samples = [
            MessageRootData(name: "一般", lastMessage: "こんにちは！"),
            MessageRootData(name: "開発チーム", lastMessage: "次のミーティングは明日です"),
            MessageRootData(name: "雑談", lastMessage: "いい天気ですね")
        ]
        
        samples.forEach { room in
            modelContext.insert(room)
        }
        
        try? modelContext.save()
    }
}

#Preview {
    NavigationView {
        ChatListView()
    }
    .modelContainer(for: MessageRootData.self, inMemory: true)
}
