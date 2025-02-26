import LocalData
import SwiftData
import SwiftUI

public struct ChatRoomMemberView: View {
    @Query private var rooms: [MessageRootData]
    @Query private var members: [MessageMember]
    
    public init(roomId: String) {
        _rooms = Query(
            filter: #Predicate<MessageRootData> { room in
                room.id == roomId
            }
        )
        _members = Query()
    }
    
    private var room: MessageRootData? {
        rooms.first
    }
    
    private var memberIds: [String] {
        guard let room = room else { return [] }
        switch room.roomType {
        case .directMessage(let id):
            return [id]
        case .group(let ids):
            return ids
        }
    }
    
    private var roomMembers: [MessageMember] {
        members.filter { memberIds.contains($0.id) }
    }
    
    public var body: some View {
        VStack {
            if let room = room {
                VStack(alignment: .leading) {
                    Text("Name: \(room.name)")
                    Text("Type: \(room.roomType.name)")
                }
            }
            List(roomMembers, id: \.id) { member in
                MemberRow(name: member.name)
            }
        }
    }
}

private struct MemberRow: View {
    let name: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(name.prefix(1))
                        .foregroundColor(.gray)
                )
            
            Text(name)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
} 
