import Logging

public struct Transcript: Encodable {
    let text: String

    enum CodingKeys: String, CodingKey {
        case text = "transcriptionText"
    }
}

public protocol TranscriptionListener: AnyObject {
    func transcriptionReceived(_: Transcript)
}

fileprivate class ListenerHandle: Hashable {
    let delegate: TranscriptionListener

    init(_ delegate: TranscriptionListener) {
        self.delegate = delegate
    }

    func transcriptionReceived(_ transcript: Transcript) {
        delegate.transcriptionReceived(transcript)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(delegate))
    }

    public static func == (l: ListenerHandle, r: ListenerHandle) -> Bool {
        l.delegate === r.delegate
    }
}

public actor TranscriptionBroadcaster {
    private static let logger: Logger = Logger(label: "TranscriptionBroadcaster")
    private var listeners: Set<ListenerHandle> = []

    public init() {}

    public func newTranscriptionText(_ text: String) {
        Self.logger.info("Received transcription text - \(text)")
        let transcript = Transcript(text: text)
        listeners.forEach {
            $0.transcriptionReceived(transcript)
        }
    }

    public func register(listener: TranscriptionListener) {
        listeners.insert(ListenerHandle(listener))
    }

    public func unregister(listener: TranscriptionListener) {
        listeners.remove(ListenerHandle(listener))
    }
}
