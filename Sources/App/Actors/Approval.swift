import Logging

public struct Messages: Encodable {
    public let chatText: [String]
}

public protocol ApprovedMessagesListener: AnyObject {
    func messagesReceived(_: Messages) async
}

public actor MessageApprovalRouter {
    private static let log = Logger(label: "MessageApprovalRouter")
    private let name: String
    private let chatMessages: ChatMessageBroadcaster
    private let rejectedMessages: ChatMessageBroadcaster
    private var chatText: [String]
    private var listeners: Set<HashableInstance<ApprovedMessagesListener>> = []
    
    public init(
        name: String,
        chatMessages: ChatMessageBroadcaster,
        rejectedMessages: ChatMessageBroadcaster,
        expectedCount: Int
    ) {
        self.name = name
        self.chatMessages = chatMessages
        self.rejectedMessages = rejectedMessages
        
        var chatText: [String] = []
        chatText.reserveCapacity(expectedCount)
        self.chatText = chatText
    }
    
    private func notifyListeners() async {
        let msgs = Messages(chatText: chatText.reversed())
        for listener in listeners {
            await listener.instance.messagesReceived(msgs)
        }
    }
    
    public func reset() async {
        chatText.removeAll()
        await notifyListeners()
    }
    
    public func register(listener: ApprovedMessagesListener) async {
        let msgs = Messages(chatText: chatText.reversed())
        await listener.messagesReceived(msgs)
        
        if listeners.isEmpty {
            await chatMessages.register(listener: self)
        }
        listeners.insert(HashableInstance(listener))
        Self.log.info("+1 \(name) listener (=\(listeners.count))")
    }
    
    public func unregister(listener: ApprovedMessagesListener) async {
        listeners.remove(HashableInstance(listener))
        if listeners.isEmpty {
            await chatMessages.unregister(listener: self)
        }
        Self.log.info("-1 \(name) listener (=\(listeners.count))")
    }
}

extension MessageApprovalRouter: ChatMessageListener {
    public func messageReceived(_ msg: ChatMessage) async {
        if msg.sender != "Me" {
            await rejectedMessages.newMessage(msg)
            return
        }
        
        chatText.append(msg.text)
        await notifyListeners()
    }
}
