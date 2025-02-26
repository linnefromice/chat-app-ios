import LocalData
import SwiftData
import SwiftUI

public struct ChatRoomView: View {
    @Query private var contents: [MessageContentData]

    public init(roomId: UUID) {
        // roomに属するメッセージを時系列順で取得
        _contents = Query(
            filter: #Predicate<MessageContentData> { message in
                message.room?.id == roomId
            },
            sort: \MessageContentData.createdAt
        )
    }

    public var body: some View {
        List(contents) { message in
            VStack(alignment: .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                Text(message.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 2)
        }
    }
}
