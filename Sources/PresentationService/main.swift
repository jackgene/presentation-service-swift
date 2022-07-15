import ArgumentParser
import Foundation
import Logging
import PresentationServiceFramework
import Swifter

let jsonEncoder = JSONEncoder()

extension WebSocketSession: ApprovedMessagesListener {
    public func messagesReceived(_ msgs: Messages) {
        if
            let data = try? jsonEncoder.encode(msgs),
            let json = String(data: data, encoding: .utf8)
        {
            writeText(json)
        }
    }
}

extension WebSocketSession: TranscriptionListener {
    public func transcriptionReceived(_ transcript: Transcript) {
        if
            let data = try? jsonEncoder.encode(transcript),
            let json = String(data: data, encoding: .utf8)
        {
            writeText(json)
        }
    }
}

extension WebSocketSession: ChatMessageListener {
    public func messageReceived(_ msg: ChatMessage) {
        if
            let data = try? jsonEncoder.encode(msg),
            let json = String(data: data, encoding: .utf8)
        {
            writeText(json)
        }
    }
}

struct PresentationServer: ParsableCommand {
    private static let logger: Logger = Logger(label: "PresentationServer")

    @Option(help: "Presentation HTML file path")
    var htmlPath: String

    @Option(help: "HTTP server port")
    var port: UInt16 = 8973

    func run() throws {
        let chatMessages = ChatMessageBroadcaster(name: "chat")
        let rejectedMessages = ChatMessageBroadcaster(name: "rejected")
        let questions = MessageApprovalRouter(
            chatMessages: chatMessages, rejectedMessages: rejectedMessages, initialCapacity: 10
        )
        let transcriptions = TranscriptionBroadcaster()
        let server = HttpServer()

        // Deck
        server.GET["/"] = shareFile(htmlPath)
        server.GET["/event/question"] = websocket(
            connected: { session in
                Task { await questions.register(listener: session) }
            },
            disconnected: { session in
                Task { await questions.unregister(listener: session) }
            }
        )
        server.GET["/event/transcription"] = websocket(
            connected: { session in
                Task { await transcriptions.register(listener: session) }
            },
            disconnected: { session in
                Task { await transcriptions.unregister(listener: session) }
            }
        )

        // Moderation
        server.GET["/moderator"] = { _ in .ok(.htmlBody(moderatorHtml)) }
        server.GET["/moderator/event"] = websocket(
            connected: { session in
                Task { await rejectedMessages.register(listener: session) }
            },
            disconnected: { session in
                Task { await rejectedMessages.unregister(listener: session) }
            }
        )
        server.POST["/chat"] = { req in
            guard let route: String = req.queryParam("route") else {
                return .badRequest(.text(#"missing "route" parameter"#))
            }
            guard let text: String = req.queryParam("text") else {
                return .badRequest(.text(#"missing "text" parameter"#))
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
                return .badRequest(.text(#"malformed "route""#))
            }

            Task {
                await chatMessages.newMessage(
                    sender: sender, recipient: recipient, text: text
                )
            }

            return .raw(204, "No Content", nil, nil)
        }
        server.GET["/reset"] = { _ in
            Task { await questions.reset() }
            .raw(204, "No Content", nil, nil)
        }

        // Transcriber
        server.GET["/transcriber"] = { _ in .ok(.htmlBody(transcriberHtml)) }
        server.POST["/transcription"] = { req in
            guard let text: String = req.queryParam("text") else {
                return .badRequest(.text(#"missing "text" parameter"#))
            }

            Task { await transcriptions.newTranscriptionText(text) }
            return .raw(204, "No Content", nil, nil)
        }

        do {
            try server.start(port)
            let port = try server.port()
            Self.logger.info("Server has started (port: \(port))...")
            RunLoop.main.run()
        } catch {
            Self.logger.error("Server start error: \(String(describing: error))")
        }
    }
}

PresentationServer.main()
