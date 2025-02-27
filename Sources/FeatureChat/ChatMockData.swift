import Foundation
import LocalData

public let PLAYER_ID = "0"

let DUMMY_NAMES: [(name: String, isDM: Bool)] = [
    ("Friend One", true),
    ("Friend Two", true),
    ("Friend Three", true),
    ("DM - 1st", true),
    ("DM - 2nd", true),
    ("DM - 3rd", true),
    ("Group - Dev Team", false),
    ("Group - Design Team", false),
    ("Group - Marketing", false),
    ("Group - Coffee Chat", false),
    ("Group - Book Club", false),
    ("Group - Gaming", false),
]

let DUMMY_MESSAGES = [
    "おはようございます！",
    "今日の進捗はいかがですか？",
    "明日の会議の準備は完了しました",
    "新しい機能のアイデアがあります",
    "お疲れ様です",
    "素晴らしい提案ですね",
    "承知しました",
    "検討してみます",
    "ありがとうございます",
    "良い週末を！",
    "こんにちは！",
    "こんばんは！",
    "今日の予定はいかがですか？もう少し時間が必要でしょうか？",
    "今日空いていますか？もしよければ遊びに行きませんか？",
]

let DUMMY_MEMBERS: [String] = [
    "Alice",
    "Bob",
    "Charlie",
    "Dave",
    "Eve",
    "Frank",
    "Grace",
    "Mike",
    "John",
    "Sarah",
    "Emma",
    "David",
    "Lisa",
    "Tom",
    "Jerry",
    "John",
    "Jane",
    "Jim",
    "Jill",
    "Jack",
]

func registerAllMembers(
    _ repository: any MessageMemberRepository
) throws {
    DUMMY_MEMBERS.forEach { name in
        let _ = try! repository.insert(name: name)
    }
}

func generateMockRoom(
    _ factory: any MessageRepositoryFactory,
    name: String,
    roomType: RoomType,
    memberIds: [MessageMemberID],
    messages: [(senderId: String, content: String)]
) throws {
    let rootRepository = factory.rootRepository()
    let contentRepository = factory.contentRepository()

    let room = try! rootRepository.insert(
        name: name,
        roomType: roomType,
        memberIds: memberIds,
        lastMessageDateStored: Date(),
        lastMessageContentStored: ""
    )
    print("room \(room.id)")
    let messageContents = messages.enumerated().map { index, item in
        let content = try! contentRepository.insert(
            content: item.content,
            senderId: item.senderId,
            room: room
        )
        print("content \(content.id)")
        return content
    }
    if let lastMessage = messageContents.last {
        room.updateLastMessage(lastMessage)
    }
}

func bulkGenerateMockRoom(
    _ factory: any MessageRepositoryFactory,
    roomCount: Int,
    messageCount: Int,
    minMemberCount: Int = 0,
    maxMemberCount: Int = 4
) throws {
    let memberRepository = factory.memberRepository()
    let members = try! memberRepository.getAll()

    let selectedNames = Array(DUMMY_NAMES.shuffled().prefix(roomCount))
    selectedNames.forEach { name, isDM in
        let shuffledMembers = members.shuffled()

        let messageContents = Array(DUMMY_MESSAGES.shuffled().prefix(messageCount))
        let (roomType, memberIds): (RoomType, [MessageMemberID]) =
            isDM
            ? (RoomType.directMessage, [shuffledMembers.first!.id])
            : (
                RoomType.group,
                Array(
                    shuffledMembers.prefix(Int.random(in: minMemberCount...maxMemberCount)).map(
                        \.id))
            )
        let senderIds = [PLAYER_ID] + memberIds

        let messages = messageContents.map { msg in
            let senderId = senderIds.randomElement()!
            return (senderId, msg)
        }

        try! generateMockRoom(
            factory,
            name: name,
            roomType: roomType,
            memberIds: memberIds,
            messages: messages
        )
    }
}
