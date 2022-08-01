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
    public let json: String?

    init(tokensByCount: [Int: [String]]) {
        self.tokensByCount = tokensByCount

        let encodableTokensByCount: [[PairElement]] = tokensByCount
            .map { [.count(number: $0), .tokens(values: $1)] }
        self.json = (try? jsonEncoder.encode(encodableTokensByCount))
            .flatMap { String(data: $0, encoding: .utf8) }
    }
}

public protocol TokensByCountListener: AnyObject {
    func countsReceived(_: Counts) async
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

    private func notifyListeners() async {
        let counts = Counts(tokensByCount: tokenFrequencies.itemsByCount)
        for listener in listeners {
            await listener.instance.countsReceived(counts)
        }
    }

    public func reset() async {
        tokensBySender.removeAll()
        tokenFrequencies = Frequencies(expectedItems: expectedSenders)
        await notifyListeners()
    }

    public func register(listener: TokensByCountListener) async {
        await listener.countsReceived(
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

            self.tokenFrequencies = tokenFrequencies.updated(
                byAdding: newToken, andRemoving: oldToken
            )

            await notifyListeners()
        } else {
            Self.log.info("No token extracted")
            await rejectedMessages.newMessage(msg)
        }
    }
}
