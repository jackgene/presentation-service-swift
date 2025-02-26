@preconcurrency import Dispatch
import Foundation
import ConsoleKit
import NIOConcurrencyHelpers
import Vapor

/// Boots the application's server. Listens for `SIGINT` and `SIGTERM` for graceful shutdown.
///
///     $ swift run Run present
///     Server starting on http://localhost:8973
///
public final class PresentationServiceCommand: AsyncCommand, Sendable {
    public struct Signature: CommandSignature, Sendable {
        @Option(name: "hostname", short: "H", help: "Set the hostname the server will run on.")
        var hostname: String?
        
        @Option(name: "port", short: "p", help: "Set the port the server will run on.")
        var port: Int?
        
        @Option(name: "bind", short: "b", help: "Convenience for setting hostname and port together.")
        var bind: String?
        
        @Option(name: "unix-socket", short: nil, help: "Set the path for the unix domain socket file the server will bind to.")
        var socketPath: String?
        
        @Option(name: "html-path", short: nil, help: "Set the path to slide deck HTML.")
        var htmlPath: String?
        
        public init() { }
    }
    
    /// Errors that may be thrown when serving a server
    public enum Error: Swift.Error {
        /// Missing required option
        case missingOption(_ option: String)
        
        /// Incompatible flags were used together (for instance, specifying a socket path along with a port)
        case incompatibleFlags
    }
    
    public static let defaultHostname = "0.0.0.0"
    public static let defaultPort = 8973
    
    // See `AsyncCommand`.
    public let signature = Signature()
    
    // See `AsyncCommand`.
    public var help: String {
        return "Begins serving the app over HTTP."
    }
    
    struct SendableBox: Sendable {
        var didShutdown: Bool
        var running: Application.Running?
        var signalSources: [DispatchSourceSignal]
        var server: Server?
    }
    
    private let box: NIOLockedValueBox<SendableBox>
    
    /// Create a new `PresentationServiceCommand`.
    init() {
        let box = SendableBox(didShutdown: false, signalSources: [])
        self.box = .init(box)
    }
    
    // See `AsyncCommand`.
    public func run(using context: CommandContext, signature: Signature) async throws {
        guard let htmlPath = signature.htmlPath else {
            throw Error.missingOption("html-path")
        }
        
        // Adding route configured from argument
        context.application.get { _ in
            return HTML(source: try String(contentsOfFile: htmlPath))
        }
        
        switch (signature.hostname, signature.port, signature.bind, signature.socketPath) {
        case (.none, .none, .none, .none): // use defaults
            try await context.application.server.start(address: .hostname(Self.defaultHostname, port: Self.defaultPort))
            
        case (.none, .none, .none, .some(let socketPath)): // unix socket
            try await context.application.server.start(address: .unixDomainSocket(path: socketPath))
            
        case (.none, .none, .some(let address), .none): // bind ("hostname:port")
            let hostname = address.split(separator: ":").first.flatMap(String.init)
            let port = address.split(separator: ":").last.flatMap(String.init).flatMap(Int.init)
            
            try await context.application.server.start(address: .hostname(hostname, port: port))
            
        case (let hostname, let port, .none, .none): // hostname / port
            try await context.application.server.start(address: .hostname(hostname, port: port))
            
        default: throw Error.incompatibleFlags
        }
        
        var box = self.box.withLockedValue { $0 }
        box.server = context.application.server
        
        // allow the server to be stopped or waited for
        let promise = context.application.eventLoopGroup.next().makePromise(of: Void.self)
        context.application.running = .start(using: promise)
        box.running = context.application.running
        
        // setup signal sources for shutdown
        let signalQueue = DispatchQueue(label: "codes.vapor.server.shutdown")
        func makeSignalSource(_ code: Int32) {
            #if canImport(Darwin)
            /// https://github.com/swift-server/swift-service-lifecycle/blob/main/Sources/UnixSignals/UnixSignalsSequence.swift#L77-L82
            signal(code, SIG_IGN)
            #endif
            
            let source = DispatchSource.makeSignalSource(signal: code, queue: signalQueue)
            source.setEventHandler {
                print() // clear ^C
                promise.succeed(())
            }
            source.resume()
            box.signalSources.append(source)
        }
        makeSignalSource(SIGTERM)
        makeSignalSource(SIGINT)
        self.box.withLockedValue { $0 = box }
    }
    
    @available(*, noasync, message: "Use the async asyncShutdown() method instead.")
    func shutdown() {
        var box = self.box.withLockedValue { $0 }
        box.didShutdown = true
        box.running?.stop()
        if let server = box.server {
            server.shutdown()
        }
        box.signalSources.forEach { $0.cancel() } // clear refs
        box.signalSources = []
        self.box.withLockedValue { $0 = box }
    }
    
    func asyncShutdown() async {
        var box = self.box.withLockedValue { $0 }
        box.didShutdown = true
        box.running?.stop()
        await box.server?.shutdown()
        box.signalSources.forEach { $0.cancel() } // clear refs
        box.signalSources = []
        self.box.withLockedValue { $0 = box }
    }
    
    deinit {
        assert(self.box.withLockedValue({ $0.didShutdown }), "PresentationServiceCommand did not shutdown before deinit")
    }
}
