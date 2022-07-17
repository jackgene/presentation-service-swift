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
    private static let logger = Logger(label: "ChatMessageBroadcaster")
    private let name: String
    private var listeners: Set<HashableInstance<ChatMessageListener>> = []

    public init(name: String) {
        self.name = name
    }

    public func newMessage(sender: String, recipient: String, text: String) {
        let msg = ChatMessage(sender: sender, recipient: recipient, text: text)
        Self.logger.info("Received \(self.name) message - \(msg.description)")
        listeners.forEach { listener in
            Task { await listener.instance.messageReceived(msg) }
        }
    }

    public func register(listener: ChatMessageListener) {
        listeners.insert(HashableInstance(listener))
    }

    public func unregister(listener: ChatMessageListener) {
        listeners.remove(HashableInstance(listener))
    }
}
