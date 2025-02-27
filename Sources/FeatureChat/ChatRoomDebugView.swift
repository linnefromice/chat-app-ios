import LocalData
import SwiftData
import SwiftUI

@MainActor
public struct ChatRoomDebugView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var rooms: [MessageRootData]
    @Query private var members: [MessageMember]

    @Binding var isAutoSending: Bool
    @Binding var messageInterval: Double
    @Binding var totalMessages: Int
    @Binding var selectedSenderMode: SenderMode
    @Binding var selectedMemberId: String
    @Binding var sentMessageCount: Int

    let startAutoSending: () -> Void
    let stopAutoSending: () -> Void

    private let roomId: String

    public init(
        roomId: String,
        isAutoSending: Binding<Bool>,
        messageInterval: Binding<Double>,
        totalMessages: Binding<Int>,
        selectedSenderMode: Binding<SenderMode>,
        selectedMemberId: Binding<String>,
        sentMessageCount: Binding<Int>,
        startAutoSending: @escaping () -> Void,
        stopAutoSending: @escaping () -> Void
    ) {
        self.roomId = roomId
        self._isAutoSending = isAutoSending
        self._messageInterval = messageInterval
        self._totalMessages = totalMessages
        self._selectedSenderMode = selectedSenderMode
        self._selectedMemberId = selectedMemberId
        self._sentMessageCount = sentMessageCount
        self.startAutoSending = startAutoSending
        self.stopAutoSending = stopAutoSending

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

    private var roomMembers: [MessageMember] {
        guard let room = room else { return [] }
        return members.filter { room.memberIds.contains($0.id) }
    }

    private var availableSenders: [MessageMember] {
        [MessageMember(id: PLAYER_ID, name: "自分")] + roomMembers
    }

    var factory: MessageRepositoryFactory {
        MessageRepositoryFactoryImpl(modelContext)
    }

    public var body: some View {
        Form {
            Section("自動メッセージ送信設定") {
                Stepper(value: $messageInterval, in: 0.5...10.0, step: 0.5) {
                    Text("送信間隔: \(messageInterval, specifier: "%.1f")秒")
                }

                Stepper(value: $totalMessages, in: 1...50) {
                    Text("送信するメッセージ数: \(totalMessages)")
                }

                Picker("送信者モード", selection: $selectedSenderMode) {
                    ForEach(SenderMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                if selectedSenderMode == .single {
                    Picker("送信者", selection: $selectedMemberId) {
                        ForEach(availableSenders, id: \.id) { member in
                            Text(member.name).tag(member.id)
                        }
                    }
                }
            }

            Section {
                if isAutoSending {
                    VStack {
                        ProgressView(value: Double(sentMessageCount), total: Double(totalMessages))
                        Text("\(sentMessageCount)/\(totalMessages) メッセージ送信済み")
                            .font(.caption)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)

                    Button("停止") {
                        stopAutoSending()
                    }
                    .foregroundColor(.red)
                } else {
                    Button("自動送信開始") {
                        startAutoSending()
                    }
                    .disabled(room == nil)
                }
            }
        }
        .navigationTitle("デバッグ")
        .onAppear {
            if selectedMemberId.isEmpty && !availableSenders.isEmpty {
                selectedMemberId = availableSenders.first!.id
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sendRandomMessage)) { _ in
            sendRandomMessage()
        }
    }

    private func sendRandomMessage() {
        guard let room = room else { return }

        let senderId: String
        if selectedSenderMode == .random {
            // ランダムな送信者を選択（自分も含む）
            let allSenderIds = [PLAYER_ID] + room.memberIds
            senderId = allSenderIds.randomElement() ?? PLAYER_ID
        } else {
            // 特定の送信者を使用
            senderId = selectedMemberId
        }

        // ランダムなメッセージを選択
        let messageContent = DUMMY_MESSAGES.randomElement() ?? "テストメッセージ"

        withCommit(modelContext) {
            let contentRepository = factory.contentRepository()
            let message = try! contentRepository.insert(
                content: messageContent,
                senderId: senderId,
                room: room
            )

            // 最後のメッセージを更新
            room.updateLastMessage(message)
        }
    }
}
