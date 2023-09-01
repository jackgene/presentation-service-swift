import Logging

public struct Transcript: Encodable {
    let text: String
    
    enum CodingKeys: String, CodingKey {
        case text = "transcriptionText"
    }
}

public protocol TranscriptionSubscriber: AnyObject {
    func transcriptionReceived(_: Transcript) async
}

/// Accumulates transcription texts, and broadcast them to subscribers.
public actor TranscriptionBroadcaster {
    private static let log = Logger(label: "TranscriptionBroadcaster")
    private var subscribers: Set<HashableInstance<TranscriptionSubscriber>> = []
    
    public init() {}
    
    public func newTranscriptionText(_ text: String) async {
        Self.log.info("Received transcription text - \(text)")
        let transcript = Transcript(text: text)
        for subscriber in subscribers {
            await subscriber.instance.transcriptionReceived(transcript)
        }
    }
    
    public func add(subscriber: TranscriptionSubscriber) {
        subscribers.insert(HashableInstance(subscriber))
        Self.log.info("+1 transcription subscriber (=\(subscribers.count))")
    }
    
    public func remove(subscriber: TranscriptionSubscriber) {
        subscribers.remove(HashableInstance(subscriber))
        Self.log.info("-1 transcription subscriber (=\(subscribers.count))")
    }
}
