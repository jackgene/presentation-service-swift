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

actor LanguagePollListener: TokensByCountListener {
    let webSocket: WebSocket
    var counts: Counts = Counts(tokensByCount: [:])
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

extension WebSocket: ApprovedMessagesListener {
    public func messagesReceived(_ msgs: Messages) async {
        if
            let data = try? Self.jsonEncoder.encode(msgs),
            let json = String(data: data, encoding: .utf8)
        {
            try? await send(json)
        }
    }
}

extension WebSocket: TranscriptionListener {
    public func transcriptionReceived(_ transcript: Transcript) async {
        if
            let data = try? Self.jsonEncoder.encode(transcript),
            let json = String(data: data, encoding: .utf8)
        {
            try? await send(json)
        }
    }
}

extension WebSocket: ChatMessageListener {
    public func messageReceived(_ msg: ChatMessage) async {
        if
            let data = try? Self.jsonEncoder.encode(msg),
            let json = String(data: data, encoding: .utf8)
        {
            try? await send(json)
        }
    }
}

func routes(_ app: Application) throws {
    let chatMessages = ChatMessageBroadcaster(name: "chat")
    let rejectedMessages = ChatMessageBroadcaster(name: "rejected")
    let languagePoll = SendersByTokenCounter(
        name: "language-poll",
        extractToken: languageFromFirstWord,
        chatMessages: chatMessages, rejectedMessages: rejectedMessages,
        expectedSenders: 200
    )
    let questions = MessageApprovalRouter(
        name: "question",
        chatMessages: chatMessages, rejectedMessages: rejectedMessages,
        expectedCount: 10
    )
    let transcriptions = TranscriptionBroadcaster()
    
    // Deck
    app.group("event") { route in
        route.webSocket("language-poll") { _, ws in
            let listener = LanguagePollListener(webSocket: ws)
            await languagePoll.register(listener: listener)
            
            try? await ws.onClose.get()
            await languagePoll.unregister(listener: listener)
        }
        
        route.webSocket("question") { _, ws in
            await questions.register(listener: ws)
            
            try? await ws.onClose.get()
            await questions.unregister(listener: ws)
        }
        
        route.webSocket("transcription") { _, ws in
            await transcriptions.register(listener: ws)
            
            try? await ws.onClose.get()
            await transcriptions.unregister(listener: ws)
        }
    }
    
    // Moderation
    app.group("moderator") { route in
        route.get { _ in return moderatorHtml }
        
        route.webSocket("event") { _, ws in
            await rejectedMessages.register(listener: ws)
            
            try? await ws.onClose.get()
            await rejectedMessages.unregister(listener: ws)
        }
    }
    app.post("chat") { req -> Response in
        guard let route: String = req.query["route"] else {
            throw Abort(.badRequest, reason: #"missing "route" parameter"#)
        }
        guard let text: String = req.query["text"] else {
            throw Abort(.badRequest, reason: #"missing "text" parameter"#)
        }
        
        let sender: String?
        let recipient: String?
        if route.hasSuffix(" to Me (Direct Message)") {
            sender = String(route.dropLast(23))
            recipient = "Me"
        } else if route.hasSuffix(" to Everyone") {
            sender = String(route.dropLast(12))
            recipient = "Everyone"
        } else if route.hasPrefix("Me ") {
            sender = nil
            recipient = nil
        } else {
            throw Abort(.badRequest, reason: #"malformed "route": \#(route)"#)
        }
        
        if let sender = sender, let recipient = recipient {
            await chatMessages.newMessage(
                ChatMessage(sender: sender, recipient: recipient, text: text)
            )
        }
        
        return Response(status: .noContent)
    }
    app.get("reset") { _ -> Response in
        await languagePoll.reset()
        await questions.reset()
        
        return Response(status: .noContent)
    }
    
    // Transcription
    app.get("transcriber") { _ in return transcriberHtml }
    
    app.post("transcription") { req -> Response in
        guard let text: String = req.query["text"] else {
            throw Abort(.badRequest, reason: #"missing "text" parameter"#)
        }
        
        await transcriptions.newTranscriptionText(text)
        
        return Response(status: .noContent)
    }
}
