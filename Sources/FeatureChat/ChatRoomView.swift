import LocalData
import SwiftData
import SwiftUI

public enum SenderMode: String, CaseIterable, Identifiable {
    case random = "ランダム"
    case single = "特定のメンバー"

    public var id: String { self.rawValue }
}

public struct ChatRoomView: View {
    @State private var selectedTab = 0

    // For Debug
    @State private var isAutoSending = false
    @State private var messageInterval: Double = 1.0
    @State private var totalMessages: Int = 5
    @State private var selectedSenderMode: SenderMode = .random
    @State private var selectedMemberId: String = ""
    @State private var sentMessageCount = 0
    @State private var timer: Timer?

    let roomId: String

    public init(roomId: String) {
        self.roomId = roomId
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            ChatRoomContentsView(roomId: roomId)
                .tabItem {
                    Label("メッセージ", systemImage: "message")
                }
                .tag(0)

            ChatRoomMemberView(roomId: roomId)
                .tabItem {
                    Label("メンバー", systemImage: "person.2")
                }
                .tag(1)

            ChatRoomDebugView(
                roomId: roomId,
                isAutoSending: $isAutoSending,
                messageInterval: $messageInterval,
                totalMessages: $totalMessages,
                selectedSenderMode: $selectedSenderMode,
                selectedMemberId: $selectedMemberId,
                sentMessageCount: $sentMessageCount,
                startAutoSending: startAutoSending,
                stopAutoSending: stopAutoSending
            )
            .tabItem {
                Label("デバッグ", systemImage: "ladybug")
            }
            .tag(2)
        }
        .onDisappear {
            stopAutoSending()
        }
    }

    private func startAutoSending() {
        guard !isAutoSending else { return }

        isAutoSending = true
        sentMessageCount = 0

        timer = Timer.scheduledTimer(withTimeInterval: messageInterval, repeats: true) { _ in
            Task { @MainActor in
                NotificationCenter.default.post(name: .sendRandomMessage, object: nil)

                sentMessageCount += 1
                if sentMessageCount >= totalMessages {
                    stopAutoSending()
                }
            }
        }
    }

    private func stopAutoSending() {
        timer?.invalidate()
        timer = nil
        isAutoSending = false
    }
}

extension NSNotification.Name {
    static let sendRandomMessage = NSNotification.Name("sendRandomMessage")
}
