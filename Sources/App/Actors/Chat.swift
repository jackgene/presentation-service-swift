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
    func messageReceived(_: ChatMessage)
}

fileprivate class ListenerHandle: Hashable {
    let delegate: ChatMessageListener

    init(_ delegate: ChatMessageListener) {
        self.delegate = delegate
    }

    func messageReceived(_ msg: ChatMessage) {
        delegate.messageReceived(msg)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(delegate))
    }

    public static func == (l: ListenerHandle, r: ListenerHandle) -> Bool {
        l.delegate === r.delegate
    }
}

public actor ChatMessageBroadcaster {
    private static let logger: Logger = Logger(label: "ChatMessageBroadcaster")
    private let name: String
    private var listeners: Set<ListenerHandle> = []

    public init(name: String) {
        self.name = name
    }

    public func newMessage(sender: String, recipient: String, text: String) {
        let msg = ChatMessage(sender: sender, recipient: recipient, text: text)
        Self.logger.info("Received \(self.name) message - \(msg.description)")
        listeners.forEach {
            $0.messageReceived(msg)
        }
    }

    public func register(listener: ChatMessageListener) {
        listeners.insert(ListenerHandle(listener))
    }

    public func unregister(listener: ChatMessageListener) {
        listeners.remove(ListenerHandle(listener))
    }
}
