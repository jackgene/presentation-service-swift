public struct Messages: Encodable {
    public let chatText: [String]
}

public protocol ApprovedMessagesListener: AnyObject {
    func messagesReceived(_: Messages)
}

public actor MessageApprovalRouter {
    private let chatMessages: ChatMessageBroadcaster
    private let rejectedMessages: ChatMessageBroadcaster
    private var chatText: [String]
    private var listeners: Set<HashableInstance<ApprovedMessagesListener>> = []

    public init(
        chatMessages: ChatMessageBroadcaster,
        rejectedMessages: ChatMessageBroadcaster,
        expectedCount: Int
    ) {
        self.chatMessages = chatMessages
        self.rejectedMessages = rejectedMessages

        var chatText: [String] = []
        chatText.reserveCapacity(expectedCount)
        self.chatText = chatText
    }

    private func notifyListeners() {
        let msgs = Messages(chatText: chatText.reversed())
        listeners.forEach {
            $0.instance.messagesReceived(msgs)
        }
    }

    public func reset() {
        chatText.removeAll()
        notifyListeners()
    }

    public func register(listener: ApprovedMessagesListener) async {
        let msgs = Messages(chatText: chatText.reversed())
        listener.messagesReceived(msgs)

        if listeners.isEmpty {
            await chatMessages.register(listener: self)
        }
        listeners.insert(HashableInstance(listener))
    }

    public func unregister(listener: ApprovedMessagesListener) async {
        listeners.remove(HashableInstance(listener))
        if listeners.isEmpty {
            await chatMessages.unregister(listener: self)
        }
    }
}

extension MessageApprovalRouter: ChatMessageListener {
    public func messageReceived(_ msg: ChatMessage) async {
        if msg.sender != "Me" {
            await rejectedMessages.newMessage(msg)
            return
        }

        chatText.append(msg.text)
        notifyListeners()
    }
}
