import SwiftUI
import SwiftData
import LocalData

public struct ChatListView: View {
    @Query private var chatRooms: [MessageRootData]
    @Environment(\.modelContext) private var modelContext

    public init() {
        // デフォルトのクエリ設定
        _chatRooms = Query(sort: \MessageRootData.lastMessageDateStored, order: .reverse)
    }
    
    public var body: some View {
        List(chatRooms) { room in
            VStack(alignment: .leading, spacing: 4) {
                Text(room.name)
                    .font(.headline)
                Text(room.lastMessageContentStored)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(room.lastMessageDateStored, style: .relative)
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
        let samples: [(MessageRootData, [String])] = [
            (MessageRootData(name: "一般"), [
                "チャットルームへようこそ！",
                "はじめまして！",
                "こんにちは！"
            ]),
            (MessageRootData(name: "開発チーム"), [
                "プロジェクトの進捗はいかがですか？",
                "順調に進んでいます",
                "次のミーティングは明日です"
            ]),
            (MessageRootData(name: "雑談"), [
                "今日は晴れていますね",
                "散歩日和です",
                "いい天気ですね"
            ])
        ]
        
        samples.forEach { room, messages in
            let messageContents = messages.enumerated().map { index, content in
                MessageContentData(
                    content: content,
                    createdAt: Date().addingTimeInterval(Double(index * -3600)),
                    room: room
                )
            }
            room.messages = messageContents
            // 最後のメッセージで更新
            if let lastMessage = messageContents.last {
                room.updateLastMessage(lastMessage)
            }
            modelContext.insert(room)
        }
        
        try? modelContext.save()
    }
}

#Preview {
    NavigationView {
        ChatListView()
    }
    .modelContainer(for: [
        MessageRootData.self,
        MessageContentData.self
    ])
}
