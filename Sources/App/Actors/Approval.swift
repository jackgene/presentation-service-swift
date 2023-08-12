import Logging

public struct Messages: Encodable {
    public let chatText: [String]
}

public protocol ApprovedMessagesSubscriber: AnyObject {
    func messagesReceived(_: Messages) async
}

public actor MessageApprovalRouter {
    private static let log = Logger(label: "MessageApprovalRouter")
    private let name: String
    private let chatMessages: ChatMessageBroadcaster
    private let rejectedMessages: ChatMessageBroadcaster
    private var chatText: [String]
    private var subscribers: Set<HashableInstance<ApprovedMessagesSubscriber>> = []
    
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
    
    private func notifySubscribers() async {
        let msgs = Messages(chatText: chatText.reversed())
        for subscriber in subscribers {
            await subscriber.instance.messagesReceived(msgs)
        }
    }
    
    public func reset() async {
        chatText.removeAll()
        await notifySubscribers()
    }
    
    public func add(subscriber: ApprovedMessagesSubscriber) async {
        let msgs = Messages(chatText: chatText.reversed())
        await subscriber.messagesReceived(msgs)
        
        if subscribers.isEmpty {
            await chatMessages.add(subscriber: self)
        }
        subscribers.insert(HashableInstance(subscriber))
        Self.log.info("+1 \(name) subscriber (=\(subscribers.count))")
    }
    
    public func remove(subscriber: ApprovedMessagesSubscriber) async {
        subscribers.remove(HashableInstance(subscriber))
        if subscribers.isEmpty {
            await chatMessages.remove(subscriber: self)
        }
        Self.log.info("-1 \(name) subscriber (=\(subscribers.count))")
    }
}

extension MessageApprovalRouter: ChatMessageSubscriber {
    public func messageReceived(_ msg: ChatMessage) async {
        if msg.sender != "Me" {
            await rejectedMessages.newMessage(msg)
            return
        }
        
        chatText.append(msg.text)
        await notifySubscribers()
    }
}
