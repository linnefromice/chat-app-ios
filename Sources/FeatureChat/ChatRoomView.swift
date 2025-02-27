import LocalData
import SwiftData
import SwiftUI

public struct ChatRoomView: View {
    @State private var selectedTab = 0
    let roomId: String

    public init(roomId: String) {
        self.roomId = roomId
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            ChatRoomContentsView(roomId: roomId)
                .tabItem {
                    Label("メッセージ", systemImage: "message")
                }
                .tag(0)

            ChatRoomMemberView(roomId: roomId)
                .tabItem {
                    Label("メンバー", systemImage: "person.2")
                }
                .tag(1)
        }
    }
}
