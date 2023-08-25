import Vapor

/// Boots the application's server. Listens for `SIGINT` and `SIGTERM` for graceful shutdown.
///
///     $ swift run Run present
///     Server starting on http://localhost:8973
///
/// This is just a copy of the build-in ServeCommand, but with support for additional options
public final class PresentationServiceCommand: Command {
    public struct Signature: CommandSignature {
        @Option(name: "hostname", short: "H", help: "Set the hostname the server will run on.")
        var hostname: String?
        
        @Option(name: "port", short: "p", help: "Set the port the server will run on.")
        var port: Int?
        
        @Option(name: "bind", short: "b", help: "Convenience for setting hostname and port together.")
        var bind: String?
        
        @Option(name: "unix-socket", short: nil, help: "Set the path for the unix domain socket file the server will bind to.")
        var socketPath: String?
        
        @Option(name: "html-path", short: nil, help: "Path to slide deck HTML.")
        var htmlPath: String?
        
        public init() { }
    }
    
    public static let defaultHostname = "0.0.0.0"
    public static let defaultPort = 8973
    
    /// Errors that may be thrown when serving a server
    public enum Error: Swift.Error {
        /// Missing required option
        case missingOption(_ option: String)
        
        /// Incompatible flags were used together (for instance, specifying a socket path along with a port)
        case incompatibleFlags
    }
    
    /// See `Command`.
    public let signature = Signature()
    
    /// See `Command`.
    public var help: String {
        return "Begins serving Presentation Service over HTTP."
    }
    
    private var signalSources: [DispatchSourceSignal]
    private var didShutdown: Bool
    private var server: Server?
    private var running: Application.Running?
    
    /// Create a new `ServeCommand`.
    init() {
        self.signalSources = []
        self.didShutdown = true
    }
    
    /// See `Command`.
    public func run(using context: CommandContext, signature: Signature) throws {
        guard let htmlPath = signature.htmlPath else {
            throw Error.missingOption("html-path")
        }
        
        // Adding route configured from argument
        context.application.get { _ in
            return HTML(source: try String(contentsOfFile: htmlPath))
        }
        
        switch (signature.hostname, signature.port, signature.bind, signature.socketPath) {
        case (.none, .none, .none, .none): // use defaults
            try context.application.server.start(address: .hostname(Self.defaultHostname, port: Self.defaultPort))
            
        case (.none, .none, .none, .some(let socketPath)): // unix socket
            try context.application.server.start(address: .unixDomainSocket(path: socketPath))
            
        case (.none, .none, .some(let address), .none): // bind ("hostname:port")
            let hostname = address.split(separator: ":").first.flatMap(String.init)
            let port = address.split(separator: ":").last.flatMap(String.init).flatMap(Int.init)
            
            try context.application.server.start(address: .hostname(hostname, port: port))
            
        case (let hostname, let port, .none, .none): // hostname / port
            try context.application.server.start(address: .hostname(hostname, port: port))
            
        default: throw Error.incompatibleFlags
        }
        
        self.server = context.application.server
        
        // allow the server to be stopped or waited for
        let promise = context.application.eventLoopGroup.next().makePromise(of: Void.self)
        context.application.running = .start(using: promise)
        self.running = context.application.running
        
        // setup signal sources for shutdown
        let signalQueue = DispatchQueue(label: "codes.vapor.server.shutdown")
        func makeSignalSource(_ code: Int32) {
            let source = DispatchSource.makeSignalSource(signal: code, queue: signalQueue)
            source.setEventHandler {
                print() // clear ^C
                promise.succeed(())
            }
            source.resume()
            self.signalSources.append(source)
            signal(code, SIG_IGN)
        }
        makeSignalSource(SIGTERM)
        makeSignalSource(SIGINT)
        
        self.didShutdown = false
    }
    
    func shutdown() {
        self.didShutdown = true
        self.running?.stop()
        if let server = self.server {
            server.shutdown()
        }
        self.signalSources.forEach { $0.cancel() } // clear refs
        self.signalSources = []
    }
    
    deinit {
        assert(self.didShutdown, "PresentationServiceCommand did not shutdown before deinit")
    }
}
