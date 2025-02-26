import Foundation
import LocalData

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

let DUMMY_MEMBERS: [(id: Int, name: String)] = [
    (1, "Alice"),
    (2, "Bob"),
    (3, "Charlie"),
    (4, "Dave"),
    (5, "Eve"),
    (6, "Frank"),
    (7, "Grace"),
    (8, "Mike"),
    (9, "John"),
    (10, "Sarah"),
    (11, "Emma"),
    (12, "David"),
    (13, "Lisa"),
    (14, "Tom"),
    (15, "Jerry"),
    (16, "John"),
    (17, "Jane"),
    (18, "Jim"),
    (19, "Jill"),
    (20, "Jack"),
]

func registerAllMembers(
    _ repository: any MessageMemberRepository
) throws {
    DUMMY_MEMBERS.forEach { _, name in
        try! repository.insert(name: name)
    }
}

func generateMockRoom(
    _ factory: any MessageRepositoryFactory,
    name: String,
    roomType: RoomType,
    messages: [String]
) throws {
    let rootRepository = factory.rootRepository()
    let contentRepository = factory.contentRepository()

    let room = try! rootRepository.insert(
        name: name,
        roomType: roomType,
        lastMessageDateStored: Date(),
        lastMessageContentStored: ""
    )
    let messageContents = messages.enumerated().map { index, content in
        let content = try! contentRepository.insert(
            content: content,
            room: room
        )
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
        let messages = Array(DUMMY_MESSAGES.shuffled().prefix(messageCount))
        let memberCount = Int.random(in: minMemberCount...maxMemberCount)
        let selectedMembers = Array(members.shuffled().prefix(memberCount))
        let roomType: RoomType =
            isDM
            ? .directMessage(selectedMembers.first!.id)
            : .group(selectedMembers.map(\.id))

        try! generateMockRoom(
            factory,
            name: name,
            roomType: roomType,
            messages: messages
        )
    }
}
