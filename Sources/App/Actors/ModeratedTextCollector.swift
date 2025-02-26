import Logging

public struct ModeratedText: Encodable {
    public let chatText: [String]
}

public protocol ModeratedTextSubscriber: Sendable {
    func moderatedTextReceived(_: ModeratedText) async
}

/// Actor that collects text from the moderation tool.
///
/// Specifically, accepts text for messages where the sender is an empty string.
public actor ModeratedTextCollector {
    private static let log = Logger(label: "ModeratedTextCollector")
    private let name: String
    private let chatMessages: ChatMessageBroadcaster
    private let rejectedMessages: ChatMessageBroadcaster
    private var chatText: [String]
    private var subscribers: Set<HashableInstance<ModeratedTextSubscriber>> = []
    
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
        let msgs = ModeratedText(chatText: chatText)
        for subscriber in subscribers {
            await subscriber.instance.moderatedTextReceived(msgs)
        }
    }
    
    public func reset() async {
        chatText.removeAll()
        await notifySubscribers()
    }
    
    public func add(subscriber: ModeratedTextSubscriber) async {
        let msgs = ModeratedText(chatText: chatText.reversed())
        await subscriber.moderatedTextReceived(msgs)
        
        if subscribers.isEmpty {
            await chatMessages.add(subscriber: self)
        }
        let (inserted, _) = subscribers.insert(HashableInstance(subscriber))
        if inserted {
            Self.log.info("+1 \(name) subscriber (=\(subscribers.count))")
        }
    }
    
    public func remove(subscriber: ModeratedTextSubscriber) async {
        if subscribers.remove(HashableInstance(subscriber)) != nil {
            if subscribers.isEmpty {
                await chatMessages.remove(subscriber: self)
            }
            Self.log.info("-1 \(name) subscriber (=\(subscribers.count))")
        }
    }
}

extension ModeratedTextCollector: ChatMessageSubscriber {
    public func messageReceived(_ msg: ChatMessage) async {
        if msg.sender != "" {
            await rejectedMessages.newMessage(msg)
            return
        }
        
        chatText.append(msg.text)
        await notifySubscribers()
    }
}
