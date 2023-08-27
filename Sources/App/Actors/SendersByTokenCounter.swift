import Logging

public struct ChatMessageAndTokens: Encodable {
    public let chatMessage: ChatMessage
    public let tokens: [String]
}

public struct Counts: Encodable {
    public enum CountOrTokens: Encodable {
        case count(number: UInt)
        case tokens(values: [String])
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            switch self {
            case .count(let value):
                try container.encode(value)
            case .tokens(let values):
                try container.encode(values)
            }
        }
    }
    
    public let chatMessagesAndTokens: [ChatMessageAndTokens]
    public let tokensBySender: [String: [String]]
    public let tokensAndCounts: [[CountOrTokens]]
    
    init() {
        self.chatMessagesAndTokens = []
        self.tokensBySender = [:]
        self.tokensAndCounts = []
    }
    
    init(
        chatMessagesAndTokens: [ChatMessageAndTokens],
        tokensBySender: [String: FIFOBoundedSet<String>],
        tokensByCount: [UInt: [String]]
    ) {
        self.chatMessagesAndTokens = chatMessagesAndTokens
        self.tokensBySender = tokensBySender.mapValues { Array($0) }
        self.tokensAndCounts = tokensByCount
            .map { [.count(number: $0), .tokens(values: $1)] }
        // TODO optimization opportunity to pre-encode JSON
    }
}

public protocol CountsSubscriber: AnyObject {
    func countsReceived(_: Counts) async
}

/// Count senders grouping by (filtered and transformed) message text.
public actor SendersByTokenCounter {
    private static let log = Logger(label: "SendersByTokenCounter")
    private let name: String
    private let extractTokens: Tokenizer
    private let chatMessages: ChatMessageBroadcaster
    private let rejectedMessages: ChatMessageBroadcaster
    private let defaultTokenSet: FIFOBoundedSet<String>
    private let expectedSenders: Int
    private var chatMessagesAndTokens: [ChatMessageAndTokens]
    private var tokensBySender: [String: FIFOBoundedSet<String>]
    private var tokenCounts: MultiSet<String>
    private var subscribers: Set<HashableInstance<CountsSubscriber>> = []
    private var currentCounts: Counts {
        get {
            Counts(
                chatMessagesAndTokens: chatMessagesAndTokens,
                tokensBySender: tokensBySender,
                tokensByCount: tokenCounts.elementsByCount
            )
        }
    }
    
    public init(
        name: String,
        extractTokens: @escaping Tokenizer,
        tokensPerSender: Int,
        chatMessages: ChatMessageBroadcaster,
        rejectedMessages: ChatMessageBroadcaster,
        expectedSenders: Int
    ) throws {
        self.name = name
        self.extractTokens = extractTokens
        self.chatMessages = chatMessages
        self.rejectedMessages = rejectedMessages
        self.defaultTokenSet = try FIFOBoundedSet<String>(maximumCount: tokensPerSender)
        self.expectedSenders = expectedSenders
        
        chatMessagesAndTokens = []
        chatMessagesAndTokens.reserveCapacity(expectedSenders)
        tokensBySender = [String: FIFOBoundedSet<String>](minimumCapacity: expectedSenders)
        tokenCounts = MultiSet(minimumCapacity: expectedSenders)
    }
    
    private func notifySubscribers() async {
        let counts = currentCounts
        for subscriber in subscribers {
            await subscriber.instance.countsReceived(counts)
        }
    }
    
    public func reset() async {
        chatMessagesAndTokens.removeAll(keepingCapacity: true)
        tokensBySender.removeAll(keepingCapacity: true)
        tokenCounts = MultiSet(minimumCapacity: expectedSenders)
        await notifySubscribers()
    }
    
    public func add(subscriber: CountsSubscriber) async {
        await subscriber.countsReceived(currentCounts)
        
        if subscribers.isEmpty {
            await chatMessages.add(subscriber: self)
        }
        subscribers.insert(HashableInstance(subscriber))
        Self.log.info("+1 \(name) subscriber (=\(subscribers.count))")
    }
    
    public func remove(subscriber: CountsSubscriber) async {
        subscribers.remove(HashableInstance(subscriber))
        if subscribers.isEmpty {
            await chatMessages.remove(subscriber: self)
        }
        Self.log.info("-1 \(name) subscriber (=\(subscribers.count))")
    }
}

extension SendersByTokenCounter: ChatMessageSubscriber {
    public func messageReceived(_ msg: ChatMessage) async {
        let sender: String? = msg.sender != "" ? msg.sender : nil
        let extractedTokens: [String] = extractTokens(msg.text)
        
        if !extractedTokens.isEmpty {
            Self.log.info(#"Extracted tokens "\#(extractedTokens.joined(separator: #"", ""#))""#)
            let prioritizedTokens: [String] = extractedTokens.reversed()
            chatMessagesAndTokens.append(
                ChatMessageAndTokens(
                    chatMessage: msg, tokens: prioritizedTokens
                )
            )
            if let sender = sender {
                for newToken: String in prioritizedTokens {
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
                for newToken: String in prioritizedTokens {
                    tokenCounts.update(byAdding: newToken)
                }
            }
            
            await notifySubscribers()
        } else {
            Self.log.info("No token extracted")
            await rejectedMessages.newMessage(msg)
        }
    }
}
