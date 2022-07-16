import Vapor

let jsonEncoder = JSONEncoder() // TODO use Vapor's global JSON encoder if possible

extension WebSocket: ApprovedMessagesListener {
    public func messagesReceived(_ msgs: Messages) {
        if
            let data = try? jsonEncoder.encode(msgs),
            let json = String(data: data, encoding: .utf8)
        {
            send(json)
        }
    }
}

extension WebSocket: TranscriptionListener {
    public func transcriptionReceived(_ transcript: Transcript) {
        if
            let data = try? jsonEncoder.encode(transcript),
            let json = String(data: data, encoding: .utf8)
        {
            send(json)
        }
    }
}

extension WebSocket: ChatMessageListener {
    public func messageReceived(_ msg: ChatMessage) {
        if
            let data = try? jsonEncoder.encode(msg),
            let json = String(data: data, encoding: .utf8)
        {
            send(json)
        }
    }
}

func routes(_ app: Application) throws {
    let chatMessages = ChatMessageBroadcaster(name: "chat")
    let rejectedMessages = ChatMessageBroadcaster(name: "rejected")
    let questions = MessageApprovalRouter(
        chatMessages: chatMessages, rejectedMessages: rejectedMessages, initialCapacity: 10
    )
    let transcriptions = TranscriptionBroadcaster()

    // Deck
    app.group("event") { route in
        route.webSocket("question") { _, ws in
            ws.onClose.whenComplete { result in
                Task { await questions.unregister(listener: ws) }
            }
            await questions.register(listener: ws)
        }

        route.webSocket("transcription") { _, ws in
            ws.onClose.whenComplete { result in
                Task { await transcriptions.unregister(listener: ws) }
            }
            await transcriptions.register(listener: ws)
        }
    }

    // Moderation
    app.group("moderator") { route in
        route.get { _ in return moderatorHtml }

        route.webSocket("event") { _, ws in
            ws.onClose.whenComplete { result in
                Task { await rejectedMessages.unregister(listener: ws) }
            }
            await rejectedMessages.register(listener: ws)
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
            sender: sender, recipient: recipient, text: text
        )

        return Response(status: .noContent)
    }
    app.get("reset") { _ -> Response in
        await questions.reset()
        return Response(status: .noContent)
    }

    // Transcription
    app.group("transcription") { route in
        route.get { _ in return transcriptionHtml }

        route.post { req -> Response in
            guard let text: String = req.query["text"] else {
                throw Abort(.badRequest, reason: #"missing "text" parameter"#)
            }

            Task { await transcriptions.newTranscriptionText(text) }
            return Response(status: .noContent)
        }
    }
}
