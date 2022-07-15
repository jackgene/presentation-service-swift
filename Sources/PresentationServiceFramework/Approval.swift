public struct Messages: Encodable {
    public let chatText: [String]
}

public protocol ApprovedMessagesListener: AnyObject {
    func messagesReceived(_: Messages)
}

fileprivate class ListenerHandle: Hashable {
    let delegate: ApprovedMessagesListener

    init(_ delegate: ApprovedMessagesListener) {
        self.delegate = delegate
    }

    func messagesReceived(_ msgs: Messages) {
        delegate.messagesReceived(msgs)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(delegate))
    }

    public static func == (l: ListenerHandle, r: ListenerHandle) -> Bool {
        l.delegate === r.delegate
    }
}

public actor MessageApprovalRouter {
    private let chatMessages: ChatMessageBroadcaster
    private let rejectedMessages: ChatMessageBroadcaster
    private var chatText: [String]
    private var listeners: Set<ListenerHandle> = []

    public init(
        chatMessages: ChatMessageBroadcaster, rejectedMessages: ChatMessageBroadcaster,
        initialCapacity: Int
    ) {
        self.chatMessages = chatMessages
        self.rejectedMessages = rejectedMessages

        var chatText: [String] = []
        chatText.reserveCapacity(initialCapacity)
        self.chatText = chatText
    }

    private func notifyListeners() {
        let msgs = Messages(chatText: chatText.reversed())
        listeners.forEach {
            $0.messagesReceived(msgs)
        }
    }

    public func newMessage(_ msg: ChatMessage) async {
        if msg.sender != "Me" {
            await rejectedMessages.newMessage(
                sender: msg.sender, recipient: msg.recipient, text: msg.text
            )
            return
        }

        chatText.append(msg.text)
        notifyListeners()
    }

    public func reset() {
        chatText.removeAll()
        notifyListeners()
    }

    public func register(listener: ApprovedMessagesListener) {
        let msgs = Messages(chatText: chatText.reversed())
        listener.messagesReceived(msgs)

        if listeners.isEmpty {
            Task { await chatMessages.register(listener: self) }
        }
        listeners.insert(ListenerHandle(listener))
    }

    public func unregister(listener: ApprovedMessagesListener) {
        listeners.remove(ListenerHandle(listener))
        if listeners.isEmpty {
            Task { await chatMessages.unregister(listener: self) }
        }
    }
}

extension MessageApprovalRouter: ChatMessageListener {
    nonisolated public func messageReceived(_ msg: ChatMessage) {
        Task { await self.newMessage(msg) }
    }
}
