import Logging

public struct Counts {
    public enum PairElement: Encodable {
        case count(number: Int)
        case tokens(values: [String])

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()

            switch self {
            case .count(let number):
                try container.encode(number)
            case .tokens(let values):
                try container.encode(values)
            }
        }
    }
    public let tokensByCount: [Int: [String]]
    public var encodableTokensByCount: [[PairElement]] {
        return tokensByCount.map { [.count(number: $0), .tokens(values: $1)] }
    }
}

public protocol TokensByCountListener: AnyObject {
    func countsReceived(_: Counts)
}

public actor SendersByTokenCounter {
    private static let log = Logger(label: "SendersByTokenCounter")
    private let name: String
    private let extractToken: (String) -> String?
    private let chatMessages: ChatMessageBroadcaster
    private let rejectedMessages: ChatMessageBroadcaster
    private let expectedSenders: Int
    private var tokensBySender: [String: String]
    private var tokenFrequencies: Frequencies
    private var listeners: Set<HashableInstance<TokensByCountListener>> = []

    public init(
        name: String,
        extractToken: @escaping (String) -> String?,
        chatMessages: ChatMessageBroadcaster,
        rejectedMessages: ChatMessageBroadcaster,
        expectedSenders: Int
    ) {
        self.name = name
        self.extractToken = extractToken
        self.chatMessages = chatMessages
        self.rejectedMessages = rejectedMessages
        self.expectedSenders = expectedSenders

        tokensBySender = [String: String](minimumCapacity: expectedSenders)
        tokenFrequencies = Frequencies(expectedItems: expectedSenders)
    }

    private func notifyListeners() {
        let counts = Counts(tokensByCount: tokenFrequencies.itemsByCount)
        listeners.forEach {
            $0.instance.countsReceived(counts)
        }
    }

    public func reset() {
        tokensBySender.removeAll()
        tokenFrequencies = Frequencies(expectedItems: expectedSenders)
        notifyListeners()
    }

    public func register(listener: TokensByCountListener) async {
        listener.countsReceived(
            Counts(tokensByCount: tokenFrequencies.itemsByCount)
        )

        if listeners.isEmpty {
            await chatMessages.register(listener: self)
        }
        listeners.insert(HashableInstance(listener))
        Self.log.info("+1 \(name) listener (=\(listeners.count))")
    }

    public func unregister(listener: TokensByCountListener) async {
        listeners.remove(HashableInstance(listener))
        if listeners.isEmpty {
            await chatMessages.unregister(listener: self)
        }
        Self.log.info("-1 \(name) listener (=\(listeners.count))")
    }
}

extension SendersByTokenCounter: ChatMessageListener {
    public func messageReceived(_ msg: ChatMessage) async {
        let sender: String? = msg.sender != "Me" ? msg.sender : nil
        let oldToken: String? = sender.flatMap { tokensBySender[$0] }
        let newToken: String? = extractToken(msg.text)

        if let newToken = newToken {
            Self.log.info(#"Extracted token "\#(newToken)""#)
            if let sender = sender {
                self.tokensBySender.updateValue(newToken, forKey: sender)
            }

            self.tokenFrequencies = tokenFrequencies
                .updated(item: newToken, delta: 1)
            if let oldToken = oldToken {
                self.tokenFrequencies = tokenFrequencies
                    .updated(item: oldToken, delta: -1)
            }

            notifyListeners()
        } else {
            Self.log.info("No token extracted")
            await rejectedMessages.newMessage(msg)
        }
    }
}
