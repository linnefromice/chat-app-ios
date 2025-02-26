import Foundation
import SwiftData

public func withCommit(_ context: ModelContext, block: () throws -> Void) {
    do {
        try block()
        try context.save()
    } catch {
        print(error)
    }
}

public protocol MessageRootRepository {
    func find(_ id: Int) throws -> MessageRootData?
    func getAll(sortBy: SortDescriptor<MessageRootData>) throws -> [MessageRootData]
    func count() throws -> Int
    func insert(
        name: String,
        roomType: RoomType,
        lastMessageDateStored: Date,
        lastMessageContentStored: String
    ) throws -> MessageRootData
    func deleteAll() throws
}

public final class MessageRootRepositoryImpl: MessageRootRepository {
    private let context: ModelContext

    public init(_ context: ModelContext) {
        self.context = context
    }

    public func find(_ id: Int) throws -> MessageRootData? {
        let descriptor = FetchDescriptor<MessageRootData>(
            predicate: #Predicate { room in
                room.id == id
            }
        )
        return try context.fetch(descriptor).first
    }

    public func getAll(
        sortBy: SortDescriptor<MessageRootData> = SortDescriptor(
            \MessageRootData.lastMessageDateStored,
            order: .reverse
        )
    ) throws -> [MessageRootData] {
        let descriptor = FetchDescriptor<MessageRootData>(
            sortBy: [sortBy]
        )
        return try context.fetch(descriptor)
    }

    public func count() throws -> Int {
        let descriptor = FetchDescriptor<MessageRootData>()
        return try context.fetchCount(descriptor)
    }

    public func insert(
        name: String,
        roomType: RoomType,
        lastMessageDateStored: Date = Date(),
        lastMessageContentStored: String = ""
    ) throws -> MessageRootData {
        let room = MessageRootData(
            id: try self.count(),
            name: name,
            roomType: roomType,
            lastMessageDateStored: lastMessageDateStored,
            lastMessageContentStored: lastMessageContentStored
        )
        context.insert(room)
        return room
    }

    public func deleteAll() throws {
        try context.delete(model: MessageRootData.self)
    }
}

// MARK: - Message Content Repository

public protocol MessageContentRepository {
    func find(_ id: Int) throws -> MessageContentData?
    func count() throws -> Int
    func getByRoomId(_ roomId: Int) throws -> [MessageContentData]
    func insert(
        content: String,
        senderId: Int,
        room: MessageRootData
    ) throws -> MessageContentData
    func deleteAll() throws
}

public final class MessageContentRepositoryImpl: MessageContentRepository {
    private let context: ModelContext

    public init(_ context: ModelContext) {
        self.context = context
    }

    public func find(_ id: Int) throws -> MessageContentData? {
        let descriptor = FetchDescriptor<MessageContentData>(
            predicate: #Predicate { message in
                message.id == id
            }
        )
        return try context.fetch(descriptor).first
    }

    public func count() throws -> Int {
        let descriptor = FetchDescriptor<MessageContentData>()
        return try context.fetchCount(descriptor)
    }

    public func getByRoomId(_ roomId: Int) throws -> [MessageContentData] {
        let descriptor = FetchDescriptor<MessageContentData>(
            predicate: #Predicate { message in
                message.room?.id == roomId
            },
            sortBy: [SortDescriptor(\MessageContentData.createdAt)]
        )
        return try context.fetch(descriptor)
    }

    public func insert(
        content: String,
        senderId: Int,
        room: MessageRootData
    ) throws -> MessageContentData {
        let message = MessageContentData(
            id: try self.count(),
            content: content,
            senderId: senderId,
            room: room
        )
        context.insert(message)
        // NOTE: if call .updateLastMessage(message), it will cause error (valueForUndefinedKey)
        // room.updateLastMessage(message)
        return message
    }

    public func deleteAll() throws {
        try context.delete(model: MessageContentData.self)
    }
}

// MARK: - Message Member Repository

public protocol MessageMemberRepository {
    func find(_ id: MessageMemberID) throws -> MessageMember?
    func getAll() throws -> [MessageMember]
    func count() throws -> Int
    func insert(name: String) throws -> MessageMember
    func deleteAll() throws
}

public final class MessageMemberRepositoryImpl: MessageMemberRepository {
    private let context: ModelContext

    public init(_ context: ModelContext) {
        self.context = context
    }

    public func find(_ id: MessageMemberID) throws -> MessageMember? {
        let descriptor = FetchDescriptor<MessageMember>(
            predicate: #Predicate { member in
                member.id == id
            }
        )
        return try context.fetch(descriptor).first
    }

    public func getAll() throws -> [MessageMember] {
        let descriptor = FetchDescriptor<MessageMember>()
        return try context.fetch(descriptor)
    }

    public func count() throws -> Int {
        let descriptor = FetchDescriptor<MessageMember>()
        return try context.fetchCount(descriptor)
    }

    public func insert(name: String) throws -> MessageMember {
        let member = MessageMember(
            id: try self.count(),
            name: name
        )
        context.insert(member)
        return member
    }

    public func deleteAll() throws {
        try context.delete(model: MessageMember.self)
    }
}

// MARK: - Repository Factory

public protocol MessageRepositoryFactory {
    func rootRepository() -> MessageRootRepository
    func contentRepository() -> MessageContentRepository
    func memberRepository() -> MessageMemberRepository
}

public final class MessageRepositoryFactoryImpl: MessageRepositoryFactory {
    private let context: ModelContext

    public init(_ context: ModelContext) {
        self.context = context
    }

    public func rootRepository() -> MessageRootRepository {
        MessageRootRepositoryImpl(context)
    }

    public func contentRepository() -> MessageContentRepository {
        MessageContentRepositoryImpl(context)
    }

    public func memberRepository() -> MessageMemberRepository {
        MessageMemberRepositoryImpl(context)
    }
}
