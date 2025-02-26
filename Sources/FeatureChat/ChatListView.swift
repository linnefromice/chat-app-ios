import LocalData
import SwiftData
import SwiftUI

public struct ChatListView: View {
    @Query private var chatRooms: [MessageRootData]
    @Environment(\.modelContext) private var modelContext

    public init() {
        // デフォルトのクエリ設定
        _chatRooms = Query(sort: \MessageRootData.lastMessageDateStored, order: .reverse)
    }

    public var body: some View {
        List(chatRooms) { room in
            NavigationLink(destination: ChatRoomView(roomId: room.id)) {
                ChatListRow(room)
                    .padding(.vertical, 4)
            }
        }
        .navigationTitle("チャット")
    }
}

struct ChatListRow: View {
    let room: MessageRootData

    init(_ room: MessageRootData) {
        self.room = room
    }

    var body: some View {
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
    }
}

#Preview {
    NavigationView {
        ChatListView()
    }
    .modelContainer(
        for: [
            MessageRootData.self,
            MessageContentData.self,
        ], inMemory: true)
}
