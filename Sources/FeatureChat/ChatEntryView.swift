import LocalData
import SwiftData
import SwiftUI

public struct ChatEntryView: View {
    @Environment(\.modelContext) private var modelContext

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                NavigationLink(destination: ChatListView()) {
                    Text("ChatListView")
                }
                Button(action: addSampleData) {
                    Text("Add Sample Data")
                }
                Button(action: clean) {
                    Text("Clean")
                }
            }
        }
    }

    private func addSampleData() {
        let samples: [(MessageRootData, [String])] = [
            (
                MessageRootData(name: "DM - Mike"),
                [
                    "チャットルームへようこそ！",
                    "はじめまして！",
                    "こんにちは！",
                ]
            ),
            (
                MessageRootData(name: "Group - Dev Team"),
                [
                    "プロジェクトの進捗はいかがですか？",
                    "順調に進んでいます",
                    "次のミーティングは明日です",
                ]
            ),
            (
                MessageRootData(name: "Group - My Self"),
                [
                    "今日は晴れていますね",
                    "散歩日和です",
                    "いい天気ですね",
                ]
            ),
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

    private func clean() {
        try? modelContext.delete(model: MessageRootData.self)
        try? modelContext.delete(model: MessageContentData.self)
    }
}
