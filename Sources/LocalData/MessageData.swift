import Foundation
import SwiftData

public typealias MessageMemberID = String

public enum RoomType: Codable {
    case directMessage(MessageMemberID)
    case group([MessageMemberID])
}

@Model
public final class MessageMember {
    @Attribute(.unique) public var id: MessageMemberID
    public var name: String

    public init(
        id: MessageMemberID = UUID().uuidString,
        name: String
    ) {
        self.id = id
        self.name = name
    }
}

@Model
public final class MessageRootData {
    @Attribute(.unique) public var id: String
    public var name: String
    public var roomType: RoomType
    public var lastMessageDateStored: Date
    public var lastMessageContentStored: String
    @Relationship(deleteRule: .cascade) public var messages: [MessageContentData]

    public init(
        id: String = UUID().uuidString,
        name: String,
        roomType: RoomType,
        lastMessageDateStored: Date = Date(),
        lastMessageContentStored: String = "",
        messages: [MessageContentData] = []
    ) {
        self.id = id
        self.name = name
        self.roomType = roomType
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
    @Attribute(.unique) public var id: String
    public var content: String
    public var createdAt: Date
    public var senderId: String
    public var room: MessageRootData?

    public init(
        id: String = UUID().uuidString,
        content: String,
        createdAt: Date = Date(),
        senderId: String,
        room: MessageRootData? = nil
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.senderId = senderId
        self.room = room
    }
}

extension MessageMember {
    public func debugPrintAllAttributes() {
        let mirror = Mirror(reflecting: self)
        var attributes: [String: String] = [:]
        for child in mirror.children {
            if let label = child.label {
                attributes[String(reflecting: label)] = String(reflecting: child.value)
            }
        }
        print(attributes)
    }
}
extension MessageRootData {
    public func debugPrintAllAttributes() {
        let mirror = Mirror(reflecting: self)
        var attributes: [String: String] = [:]
        for child in mirror.children {
            if let label = child.label {
                attributes[String(reflecting: label)] = String(reflecting: child.value)
            }
        }
        print(attributes)
    }
}
extension MessageContentData {
    public func debugPrintAllAttributes() {
        let mirror = Mirror(reflecting: self)
        var attributes: [String: String] = [:]
        for child in mirror.children {
            if let label = child.label {
                attributes[String(reflecting: label)] = String(reflecting: child.value)
            }
        }
        print(attributes)
    }
}
