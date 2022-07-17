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

public actor TranscriptionBroadcaster {
    private static let log = Logger(label: "TranscriptionBroadcaster")
    private var listeners: Set<HashableInstance<TranscriptionListener>> = []

    public init() {}

    public func newTranscriptionText(_ text: String) {
        Self.log.info("Received transcription text - \(text)")
        let transcript = Transcript(text: text)
        listeners.forEach {
            $0.instance.transcriptionReceived(transcript)
        }
    }

    public func register(listener: TranscriptionListener) {
        listeners.insert(HashableInstance(listener))
        Self.log.info("+1 transcription listener (=\(listeners.count))")
    }

    public func unregister(listener: TranscriptionListener) {
        listeners.remove(HashableInstance(listener))
        Self.log.info("-1 transcription listener (=\(listeners.count))")
    }
}
