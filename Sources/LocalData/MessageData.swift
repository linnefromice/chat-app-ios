import SwiftData
import Foundation

@Model
public final class MessageRootData {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var lastMessageDateStored: Date
    public var lastMessageContentStored: String
    @Relationship(deleteRule: .cascade) public var messages: [MessageContentData]

    public init(
        id: UUID = UUID(),
        name: String,
        lastMessageDateStored: Date = Date(),
        lastMessageContentStored: String = "",
        messages: [MessageContentData] = []
    ) {
        self.id = id
        self.name = name
        self.lastMessageDateStored = lastMessageDateStored
        self.lastMessageContentStored = lastMessageContentStored
        self.messages = messages
    }
    
    public func updateLastMessage(_ message: MessageContentData) {
        self.lastMessageDateStored = message.createdAt
        self.lastMessageContentStored = message.content
    }
}

@Model
public final class MessageContentData {
    @Attribute(.unique) public var id: UUID
    public var content: String
    public var createdAt: Date
    public var room: MessageRootData?
    
    public init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = Date(),
        room: MessageRootData? = nil
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.room = room
    }
}

    