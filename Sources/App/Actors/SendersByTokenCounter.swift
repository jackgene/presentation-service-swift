import Logging

public struct Counts: Encodable {
    public enum PairElement: Encodable {
        case count(number: UInt)
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
    
    public let tokensAndCounts: [[PairElement]]
    
    init(tokensByCount: [UInt: [String]]) {
        self.tokensAndCounts = tokensByCount
            .map { [.count(number: $0), .tokens(values: $1)] }
        // TODO optimization opportunity to pre-encode JSON
    }
}

public protocol TokensByCountListener: AnyObject {
    func countsReceived(_: Counts) async
}

public actor SendersByTokenCounter {
    private static let log = Logger(label: "SendersByTokenCounter")
    private let name: String
    private let extractTokens: (String) -> [String]
    private let chatMessages: ChatMessageBroadcaster
    private let rejectedMessages: ChatMessageBroadcaster
    private let defaultTokenSet: FIFOFixedSizedSet<String>
    private let expectedSenders: Int
    private var tokensBySender: [String: FIFOFixedSizedSet<String>]
    private var tokenCounts: MultiSet<String>
    private var listeners: Set<HashableInstance<TokensByCountListener>> = []
    
    public init?(
        name: String,
        extractTokens: @escaping (String) -> [String],
        tokensPerSender: Int,
        chatMessages: ChatMessageBroadcaster,
        rejectedMessages: ChatMessageBroadcaster,
        expectedSenders: Int
    ) {
        guard
            let emptyTokenSet = FIFOFixedSizedSet<String>(
                maximumCapacity: tokensPerSender
            )
        else { return nil }
        self.name = name
        self.extractTokens = extractTokens
        self.chatMessages = chatMessages
        self.rejectedMessages = rejectedMessages
        self.defaultTokenSet = emptyTokenSet
        self.expectedSenders = expectedSenders
        
        tokensBySender = [String: FIFOFixedSizedSet<String>](minimumCapacity: expectedSenders)
        tokenCounts = MultiSet(expectedElements: expectedSenders)
    }
    
    private func notifyListeners() async {
        let counts = Counts(tokensByCount: tokenCounts.elementsByCount)
        for listener in listeners {
            await listener.instance.countsReceived(counts)
        }
    }
    
    public func reset() async {
        tokensBySender.removeAll()
        tokenCounts = MultiSet(expectedElements: expectedSenders)
        await notifyListeners()
    }
    
    public func register(listener: TokensByCountListener) async {
        await listener.countsReceived(
            Counts(tokensByCount: tokenCounts.elementsByCount)
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
        let sender: String? = msg.sender != "" ? msg.sender : nil
        let extractedTokens: [String] = extractTokens(msg.text)
        
        if !extractedTokens.isEmpty {
            Self.log.info(#"Extracted tokens "\#(extractedTokens.joined(separator: "\", "))""#)
            if let sender = sender {
                for newToken: String in extractedTokens {
                    switch tokensBySender[sender, default: defaultTokenSet].append(newToken) {
                    case let .addedEvicting(oldToken):
                        tokenCounts.update(byAdding: newToken,
                                           andRemoving: oldToken)
                    case .added:
                        tokenCounts.update(byAdding: newToken)
                    case .notAdded: break
                    }
                }
            } else {
                for newToken: String in extractedTokens {
                    tokenCounts.update(byAdding: newToken)
                }
            }
            
            await notifyListeners()
        } else {
            Self.log.info("No token extracted")
            await rejectedMessages.newMessage(msg)
        }
    }
}
