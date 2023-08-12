import Logging

public struct ChatMessage: Encodable {
    public let sender: String
    public let recipient: String
    public let text: String
    public var description: String { "\(sender) to \(recipient): \(text)" }
    
    enum CodingKeys: String, CodingKey {
        case sender = "s"
        case recipient = "r"
        case text = "t"
    }
}

public protocol ChatMessageSubscriber: AnyObject {
    func messageReceived(_: ChatMessage) async
}

/// Broadcasts chat messages to any subscriber.
///
/// Subscribers can then use the chat messages to drive:
/// - Polls
/// - Word Clouds
/// - Statistics on chat messages
/// - Q&A questions
/// - Etc
public actor ChatMessageBroadcaster {
    private static let log = Logger(label: "ChatMessageBroadcaster")
    private let name: String
    private var subscribers: Set<HashableInstance<ChatMessageSubscriber>> = []
    
    public init(name: String) {
        self.name = name
    }
    
    public func newMessage(_ msg: ChatMessage) async {
        Self.log.info("Received \(self.name) message - \(msg.description)")
        for subscriber in subscribers {
            await subscriber.instance.messageReceived(msg)
        }
    }
    
    public func add(subscriber: ChatMessageSubscriber) {
        subscribers.insert(HashableInstance(subscriber))
        Self.log.info("+1 \(name) subscriber (=\(subscribers.count))")
    }
    
    public func remove(subscriber: ChatMessageSubscriber) {
        subscribers.remove(HashableInstance(subscriber))
        Self.log.info("-1 \(name) subscriber (=\(subscribers.count))")
    }
}
