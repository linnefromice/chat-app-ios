import LocalData
import SwiftData
import SwiftUI

public struct ChatRoomContentsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var displayedMessages: [MessageContentData] = []
    @State private var allMessages: [MessageContentData] = []
    @State private var pageSize: Int = 5
    @State private var currentPage: Int = 1
    @State private var isLoading: Bool = false
    @State private var hasReachedEnd: Bool = false
    @State private var scrollPosition: String? = nil
    @State private var isScrolling: Bool = false
    
    @Query private var members: [MessageMember]
    @Query private var rooms: [MessageRootData]
    @State private var isShowingMessageForm = false
    @State private var scrollToBottom = false

    private let roomId: String

    public init(roomId: String) {
        self.roomId = roomId
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
            messageListView
            addMessageButton
        }
    }
    
    // メッセージリスト部分を分離
    private var messageListView: some View {
        ScrollViewReader { proxy in
            List {
                loadMoreSection
                
                ForEach(displayedMessages) { message in
                    MessageRow(message: message, members: members)
                        .listRowSeparator(.hidden)
                        .id(message.id)
                        .onAppear {
                            // このメッセージが表示されたら、スクロール位置として記録
                            scrollPosition = message.id
                        }
                }
                
                Color.clear.frame(height: 1).id("bottomAnchor")
            }
            .background(.clear)
            .scrollContentBackground(.hidden)
            .onAppear {
                loadInitialMessages()
                
                // 初回表示時に最下部にスクロール
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        proxy.scrollTo("bottomAnchor", anchor: .bottom)
                    }
                }
            }
            .onChange(of: displayedMessages.count) { oldCount, newCount in
                handleMessageCountChange(proxy: proxy, oldCount: oldCount, newCount: newCount)
            }
            .onReceive(NotificationCenter.default.publisher(for: .sendRandomMessage)) { _ in
                handleRandomMessage(proxy: proxy)
            }
        }
    }
    
    // 「さらに読み込む」セクション
    private var loadMoreSection: some View {
        Group {
            if !hasReachedEnd {
                Button(action: {
                    // タップで過去メッセージを読み込む
                    if !isLoading && !hasReachedEnd {
                        loadMoreMessages()
                    }
                }) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("↓ 引き下げて読み込む ↓")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .id("loadMoreIndicator")
                .listRowSeparator(.hidden)
                .onAppear {
                    // 最上部に到達したら自動的に読み込む
                    if !isLoading && !hasReachedEnd {
                        loadMoreMessages()
                    }
                }
            }
        }
    }
    
    // メッセージ追加ボタン
    private var addMessageButton: some View {
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
            MessageFormView(room: room!) { success in
                isShowingMessageForm = false
                if success {
                    refreshMessages()
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    // メッセージ数変更時の処理
    private func handleMessageCountChange(proxy: ScrollViewProxy, oldCount: Int, newCount: Int) {
        // 新しいメッセージが追加された場合のみ下にスクロール
        // (上に読み込んだ場合はスクロールしない)
        if oldCount < newCount && newCount - oldCount <= 1 {
            withAnimation {
                proxy.scrollTo("bottomAnchor", anchor: .bottom)
            }
        } else if oldCount < newCount && scrollPosition != nil {
            // 過去メッセージを読み込んだ場合は、前の位置を維持
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    proxy.scrollTo(scrollPosition, anchor: .center)
                }
            }
        }
    }
    
    // ランダムメッセージ受信時の処理
    private func handleRandomMessage(proxy: ScrollViewProxy) {
        // 自動送信時にも最下部にスクロール
        refreshMessages()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                proxy.scrollTo("bottomAnchor", anchor: .bottom)
            }
        }
    }
    
    // 以下は元のコードと同じ
    private func loadInitialMessages() {
        guard let room = room else { return }
        
        let descriptor = FetchDescriptor<MessageContentData>(
            predicate: #Predicate<MessageContentData> { message in
                message.room?.id == roomId
            },
            sortBy: [SortDescriptor(\MessageContentData.createdAt, order: .forward)]
        )
        
        do {
            allMessages = try modelContext.fetch(descriptor)
            
            // 最新のpageSize件を表示
            if allMessages.count > pageSize {
                displayedMessages = Array(allMessages.suffix(pageSize))
            } else {
                displayedMessages = allMessages
                hasReachedEnd = true
            }
        } catch {
            print("Error fetching messages: \(error)")
        }
    }
    
    private func loadMoreMessages() {
        guard !isLoading, !hasReachedEnd else { return }
        
        isLoading = true
        
        // スクロール位置を保存
        let currentFirstMessage = displayedMessages.first
        
        // 現在表示されている最も古いメッセージのインデックスを見つける
        if let oldestDisplayedMessage = displayedMessages.first,
           let oldestIndex = allMessages.firstIndex(where: { $0.id == oldestDisplayedMessage.id }) {
            
            // さらに古いメッセージを取得
            let startIndex = max(0, oldestIndex - pageSize)
            let endIndex = oldestIndex
            
            if startIndex < endIndex {
                let olderMessages = Array(allMessages[startIndex..<endIndex])
                
                // スクロール位置を保持するために現在の最初のメッセージのIDを記録
                scrollPosition = currentFirstMessage?.id
                
                // 新しいメッセージを追加
                displayedMessages = olderMessages + displayedMessages
                
                // 全てのメッセージを表示したかチェック
                if startIndex == 0 {
                    hasReachedEnd = true
                }
            } else {
                hasReachedEnd = true
            }
        } else {
            hasReachedEnd = true
        }
        
        isLoading = false
    }
    
    private func refreshMessages() {
        guard let room = room else { return }
        
        let descriptor = FetchDescriptor<MessageContentData>(
            predicate: #Predicate<MessageContentData> { message in
                message.room?.id == roomId
            },
            sortBy: [SortDescriptor(\MessageContentData.createdAt, order: .forward)]
        )
        
        do {
            allMessages = try modelContext.fetch(descriptor)
            
            // 現在表示されているメッセージ数を維持しつつ、最新のメッセージを追加
            let currentCount = displayedMessages.count
            if allMessages.count > currentCount {
                displayedMessages = Array(allMessages.suffix(currentCount + 1))
            } else {
                displayedMessages = allMessages
                hasReachedEnd = true
            }
        } catch {
            print("Error refreshing messages: \(error)")
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
