import SwiftData
import Foundation

@Model
public final class MessageRootData {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var lastMessage: String
    public var lastMessageDate: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        lastMessage: String = "",
        lastMessageDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.lastMessage = lastMessage
        self.lastMessageDate = lastMessageDate
    }
}

    