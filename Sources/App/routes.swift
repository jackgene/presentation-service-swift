import Vapor

let batchPeriodNanos: UInt64 = 100_000_000

extension WebSocket {
    private static let log = Logger(label: "WebSocket")
    fileprivate static let jsonEncoder: JSONEncoder = {
        guard
            let untypedEncoder: ContentEncoder =
                try? ContentConfiguration.global.requireEncoder(for: .json),
            let jsonEncoder = untypedEncoder as? JSONEncoder
        else {
            log.warning("Unable to obtain global JSON encoder, creating new")
            return JSONEncoder()
        }
        
        return jsonEncoder
    }()
}

actor TokensByCountWebSocketAdapter: CountsSubscriber {
    let webSocket: WebSocket
    var counts: Counts = Counts()
    var awaitingSend: Bool = false
    
    init(webSocket: WebSocket) {
        self.webSocket = webSocket
    }
    
    public func countsReceived(_ counts: Counts) async {
        self.counts = counts
        if !awaitingSend {
            awaitingSend = true
            Task {
                try await Task.sleep(nanoseconds: batchPeriodNanos)
                await send()
            }
        }
    }
    
    func send() async {
        defer { awaitingSend = false }
        if
            let data = try? WebSocket.jsonEncoder.encode(counts),
            let json = String(data: data, encoding: .utf8)
        {
            try? await webSocket.send(json)
        }
    }
}

extension WebSocket: ModeratedTextSubscriber {
    public func messagesReceived(_ msgs: ModeratedText) async {
        if
            let data = try? Self.jsonEncoder.encode(msgs),
            let json = String(data: data, encoding: .utf8)
        {
            try? await send(json)
        }
    }
}

extension WebSocket: TranscriptionSubscriber {
    public func transcriptionReceived(_ transcript: Transcript) async {
        if
            let data = try? Self.jsonEncoder.encode(transcript),
            let json = String(data: data, encoding: .utf8)
        {
            try? await send(json)
        }
    }
}

extension WebSocket: ChatMessageSubscriber {
    public func messageReceived(_ msg: ChatMessage) async {
        if
            let data = try? Self.jsonEncoder.encode(msg),
            let json = String(data: data, encoding: .utf8)
        {
            try? await send(json)
        }
    }
}

func routes(_ app: Application, _ config: Configuration) throws {
    let chatMessages: ChatMessageBroadcaster = ChatMessageBroadcaster(name: "chat")
    let rejectedMessages: ChatMessageBroadcaster = ChatMessageBroadcaster(name: "rejected")
    guard
        let languagePoll: SendersByTokenCounter = SendersByTokenCounter(
            name: "language-poll",
            extractTokens: mappedKeywordsTokenizer(config.languagePoll.languageByKeyword),
            tokensPerSender: config.languagePoll.maxVotesPerPerson,
            chatMessages: chatMessages, rejectedMessages: rejectedMessages,
            expectedSenders: 200
        )
    else { throw Error.initializationError }
    guard
        let wordCloud: SendersByTokenCounter = SendersByTokenCounter(
            name: "word-cloud",
            extractTokens: normalizedWordsTokenizer(
                stopWords: config.wordCloud.stopWords,
                minWordLength: config.wordCloud.minWordLength,
                maxWordLength: config.wordCloud.maxWordLength
            ),
            tokensPerSender: config.wordCloud.maxWordsPerPerson,
            chatMessages: chatMessages, rejectedMessages: rejectedMessages,
            expectedSenders: 200
        )
    else { throw Error.initializationError }
    let questions: ModeratedTextCollector = ModeratedTextCollector(
        name: "question",
        chatMessages: chatMessages, rejectedMessages: rejectedMessages,
        expectedCount: 10
    )
    let transcriptions: TranscriptionBroadcaster = TranscriptionBroadcaster()
    
    // Deck
    app.group("event") { route in
        route.webSocket("language-poll") { _, ws in
            let adapter = TokensByCountWebSocketAdapter(webSocket: ws)
            await languagePoll.add(subscriber: adapter)
            
            try? await ws.onClose.get()
            await languagePoll.remove(subscriber: adapter)
        }
        
        route.webSocket("word-cloud") { _, ws in
            let adapter = TokensByCountWebSocketAdapter(webSocket: ws)
            await wordCloud.add(subscriber: adapter)
            
            try? await ws.onClose.get()
            await wordCloud.remove(subscriber: adapter)
        }
        
        route.webSocket("question") { _, ws in
            await questions.add(subscriber: ws)
            
            try? await ws.onClose.get()
            await questions.remove(subscriber: ws)
        }
        
        route.webSocket("transcription") { _, ws in
            await transcriptions.add(subscriber: ws)
            
            try? await ws.onClose.get()
            await transcriptions.remove(subscriber: ws)
        }
    }
    
    // Moderation
    app.group("moderator") { route in
        route.get { _ in return moderatorHTML }
        
        route.webSocket("event") { _, ws in
            await rejectedMessages.add(subscriber: ws)
            
            try? await ws.onClose.get()
            await rejectedMessages.remove(subscriber: ws)
        }
    }
    app.post("chat") { req -> Response in
        guard let route: String = req.query["route"] else {
            throw Abort(.badRequest, reason: #"missing "route" parameter"#)
        }
        guard let text: String = req.query["text"] else {
            throw Abort(.badRequest, reason: #"missing "text" parameter"#)
        }
        
        let senderAndRecipient: (String, String)?
        if route.hasSuffix(" to Me (Direct Message)") {
            senderAndRecipient = (String(route.dropLast(23)), "Me")
        } else if route.hasSuffix(" to Everyone") {
            senderAndRecipient = (String(route.dropLast(12)), "Everyone")
        } else if route.hasPrefix("Me to ") {
            senderAndRecipient = nil
        } else {
            throw Abort(.badRequest, reason: #"malformed "route": \#(route)"#)
        }
        
        if let (sender, recipient) = senderAndRecipient {
            await chatMessages.newMessage(
                ChatMessage(sender: sender, recipient: recipient, text: text)
            )
        }
        
        return Response(status: .noContent)
    }
    app.get("reset") { _ -> Response in
        await languagePoll.reset()
        await wordCloud.reset()
        await questions.reset()
        
        return Response(status: .noContent)
    }
    
    // Transcription
    app.get("transcriber") { _ in return transcriberHTML }
    
    app.post("transcription") { req -> Response in
        guard let text: String = req.query["text"] else {
            throw Abort(.badRequest, reason: #"missing "text" parameter"#)
        }
        
        await transcriptions.newTranscriptionText(text)
        
        return Response(status: .noContent)
    }
}
