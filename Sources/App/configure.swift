import Vapor

// configures your application
public func configure(_ app: Application) throws {
    app.commands.use(PresentationServiceCommand(), as: "present", isDefault: true)

    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 8973

    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
}
