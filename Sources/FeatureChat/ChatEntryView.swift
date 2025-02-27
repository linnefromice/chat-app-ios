import LocalData
import SwiftData
import SwiftUI

public struct ChatEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var roomCount: Int = 3
    @State private var messageCount: Int = 5
    @State private var memberCount: Int = 3

    @State private var storedRoomCount: Int? = nil
    @State private var storedMemberCount: Int? = nil

    public init() {}

    var factory: MessageRepositoryFactory {
        MessageRepositoryFactoryImpl(modelContext)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Navigation") {
                    NavigationLink(destination: ChatListView()) {
                        Text("ChatListView")
                    }
                }

                Section("Sample Data Generator") {
                    Stepper("ルーム数: \(roomCount)", value: $roomCount, in: 1...9)
                    Stepper("メッセージ数/ルーム: \(messageCount)", value: $messageCount, in: 1...20)
                    Stepper("メンバー数/ルーム: \(memberCount)", value: $memberCount, in: 0...6)

                    Button(action: {
                        addRandomData(
                            roomCount: roomCount,
                            messageCount: messageCount,
                            minMemberCount: memberCount
                        )
                    }) {
                        Text("サンプルデータを追加")
                    }
                }

                Section("Data Management") {
                    Text("ルーム数: \(storedRoomCount.map { "\($0)" } ?? "Not loaded")")
                    Text("メンバー数: \(storedMemberCount.map { "\($0)" } ?? "Not loaded")")

                    Button(action: clean) {
                        Text("全データを削除")
                            .foregroundColor(.red)
                    }

                    Button(action: {
                        withCommit(modelContext) {
                            let memberRepository = factory.memberRepository()
                            try! memberRepository.deleteAll()
                            try! registerAllMembers(memberRepository)
                            storedMemberCount = try! memberRepository.count()
                        }
                    }) {
                        Text("メンバーリセット")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Chat App")
        }
        .onAppear {
            let memberRepository = factory.memberRepository()
            if try! memberRepository.count() == 0 {
                withCommit(modelContext) {
                    try! registerAllMembers(memberRepository)
                }
            }

            storedRoomCount = try! factory.rootRepository().count()
            storedMemberCount = try! factory.memberRepository().count()
        }
    }

    private func addRandomData(
        roomCount: Int,
        messageCount: Int,
        minMemberCount: Int = 0,
        maxMemberCount: Int = 4
    ) {
        let factory = MessageRepositoryFactoryImpl(modelContext)
        withCommit(modelContext) {
            try! bulkGenerateMockRoom(
                factory,
                roomCount: roomCount,
                messageCount: messageCount,
                minMemberCount: minMemberCount,
                maxMemberCount: maxMemberCount
            )
        }
        storedRoomCount = try! factory.rootRepository().count()
    }

    private func clean() {
        withCommit(modelContext) {
            try? modelContext.delete(model: MessageRootData.self)
            try? modelContext.delete(model: MessageContentData.self)
        }
        storedRoomCount = try! factory.rootRepository().count()
        storedMemberCount = try! factory.memberRepository().count()
    }
}

#Preview {
    ChatEntryView()
        .modelContainer(
            for: [
                MessageRootData.self,
                MessageContentData.self,
                MessageMember.self,
            ], inMemory: true)
}
