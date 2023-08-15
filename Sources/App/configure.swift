import Vapor

// configures your application
public func configure(_ app: Application) throws {
    app.commands.use(PresentationServiceCommand(), as: "present", isDefault: true)
    
    // register routes
    try routes(app)
}
