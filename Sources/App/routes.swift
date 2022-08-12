import Vapor

let jsonEncoder = JSONEncoder() // TODO use Vapor's global JSON encoder if possible

extension WebSocket: TokensByCountListener {
    public func countsReceived(_ counts: Counts) async {
        if let json = counts.json {
            try? await send(json)
        }
    }
}

extension WebSocket: ApprovedMessagesListener {
    public func messagesReceived(_ msgs: Messages) async {
        if
            let data = try? jsonEncoder.encode(msgs),
            let json = String(data: data, encoding: .utf8)
        {
            try? await send(json)
        }
    }
}

extension WebSocket: TranscriptionListener {
    public func transcriptionReceived(_ transcript: Transcript) async {
        if
            let data = try? jsonEncoder.encode(transcript),
            let json = String(data: data, encoding: .utf8)
        {
            try? await send(json)
        }
    }
}

extension WebSocket: ChatMessageListener {
    public func messageReceived(_ msg: ChatMessage) async {
        if
            let data = try? jsonEncoder.encode(msg),
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
            await languagePoll.register(listener: ws)

            try? await ws.onClose.get()
            await languagePoll.unregister(listener: ws)
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

        let sender: String
        let recipient: String
        if route.hasSuffix(" to Me") {
            sender = String(route.dropLast(6))
            recipient = "Me"
        } else if route.hasSuffix(" to Everyone") {
            sender = String(route.dropLast(12))
            recipient = "Everyone"
        } else {
            throw Abort(.badRequest, reason: #"malformed "route""#)
        }

        await chatMessages.newMessage(
            ChatMessage(sender: sender, recipient: recipient, text: text)
        )

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
