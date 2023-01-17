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

public protocol ChatMessageListener: AnyObject {
    func messageReceived(_: ChatMessage) async
}

public actor ChatMessageBroadcaster {
    private static let log = Logger(label: "ChatMessageBroadcaster")
    private let name: String
    private var listeners: Set<HashableInstance<ChatMessageListener>> = []
    
    public init(name: String) {
        self.name = name
    }
    
    public func newMessage(_ msg: ChatMessage) async {
        Self.log.info("Received \(self.name) message - \(msg.description)")
        for listener in listeners {
            await listener.instance.messageReceived(msg)
        }
    }
    
    public func register(listener: ChatMessageListener) {
        listeners.insert(HashableInstance(listener))
        Self.log.info("+1 \(name) message listener (=\(listeners.count))")
    }
    
    public func unregister(listener: ChatMessageListener) {
        listeners.remove(HashableInstance(listener))
        Self.log.info("-1 \(name) message listener (=\(listeners.count))")
    }
}
