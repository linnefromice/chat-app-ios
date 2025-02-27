import LocalData
import SwiftData
import SwiftUI

public struct ChatRoomContentsView: View {
    @Query private var contents: [MessageContentData]
    @Query private var members: [MessageMember]

    public init(roomId: String) {
        _contents = Query(
            filter: #Predicate<MessageContentData> { message in
                message.room?.id == roomId
            },
            sort: \MessageContentData.createdAt
        )
        _members = Query()
    }

    public var body: some View {
        List(contents) { message in
            MessageRow(message: message, members: members)
                .listRowSeparator(.hidden)
        }
        .background(.clear)
        .scrollContentBackground(.hidden)
    }
}

private struct MessageRow: View {
    let message: MessageContentData
    let members: [MessageMember]

    private var isFromCurrentUser: Bool {
        message.senderId == PLAYER_ID
    }

    private var senderName: String {
        if isFromCurrentUser {
            return "Me"
        }
        return members.first { $0.id == message.senderId }?.name ?? "Unknown"
    }

    var body: some View {
        HStack(alignment: .top) {
            if isFromCurrentUser {
                Spacer()
            }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(senderName)
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(message.content)
                    .font(.body)
                    .padding(8)
                    .background(
                        isFromCurrentUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2)
                    )
                    .cornerRadius(8)

                Text(message.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            if !isFromCurrentUser {
                Spacer()
            }
        }
        .padding(.vertical, 2)
    }
}
