import LocalData
import SwiftData
import SwiftUI

public struct ChatRoomContentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contents: [MessageContentData]
    @Query private var members: [MessageMember]
    @Query private var rooms: [MessageRootData]
    @State private var isShowingMessageForm = false
    @State private var scrollToBottom = false

    public init(roomId: String) {
        _contents = Query(
            filter: #Predicate<MessageContentData> { message in
                message.room?.id == roomId
            },
            sort: \MessageContentData.createdAt
        )
        _members = Query()
        _rooms = Query(
            filter: #Predicate<MessageRootData> { room in
                room.id == roomId
            }
        )
    }

    var room: MessageRootData? {
        rooms.first
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollViewReader { proxy in
                List {
                    ForEach(contents) { message in
                        MessageRow(message: message, members: members)
                            .listRowSeparator(.hidden)
                            .id(message.id)
                    }
                    Color.clear.frame(height: 1).id("bottomAnchor")
                }
                .background(.clear)
                .scrollContentBackground(.hidden)
                .onAppear {
                    withAnimation {
                        proxy.scrollTo("bottomAnchor", anchor: .bottom)
                    }
                }
                // NOTE: Other scrolling patterns
                // .onChange(of: contents.count) { _, _ in
                //     withAnimation {
                //         proxy.scrollTo("bottomAnchor", anchor: .bottom)
                //     }
                // }
                // .onReceive(NotificationCenter.default.publisher(for: .sendRandomMessage)) { _ in
                //     withAnimation {
                //         proxy.scrollTo("bottomAnchor", anchor: .bottom)
                //     }
                // }
            }

            Button(action: {
                isShowingMessageForm = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                    .background(Color.white.clipShape(Circle()))
                    .shadow(radius: 3)
            }
            .padding()
            .sheet(isPresented: $isShowingMessageForm) {
                MessageFormView(room: room!) { _ in
                    isShowingMessageForm = false
                }
                .presentationDetents([.medium])
            }
        }
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

private struct MessageFormView: View {
    let room: MessageRootData?
    let onComplete: (Bool) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool

    init(room: MessageRootData?, onComplete: @escaping (Bool) -> Void) {
        self.room = room
        self.onComplete = onComplete
    }

    var factory: MessageRepositoryFactory {
        MessageRepositoryFactoryImpl(modelContext)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("新しいメッセージ")
                    .font(.headline)

                TextField("メッセージを入力", text: $messageText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(5...)
                    .focused($isTextFieldFocused)

                Button("送信") {
                    sendMessage()
                }
                .buttonStyle(.borderedProminent)
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        onComplete(false)
                    }
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }

    private func sendMessage() {
        guard let room = room, !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return
        }

        withCommit(modelContext) {
            let contentRepository = factory.contentRepository()
            let message = try! contentRepository.insert(
                content: messageText,
                senderId: PLAYER_ID,
                room: room
            )

            // 最後のメッセージを更新
            room.updateLastMessage(message)
        }

        onComplete(true)
    }
}
