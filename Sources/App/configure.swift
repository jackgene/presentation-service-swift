import Vapor

func configuration() -> Configuration {
    guard
        let url: URL = Bundle.main.url(forResource: "presentation-service", withExtension: "plist"),
        let configuration: Configuration = try? .load(fromPlist: url)
    else {
        return .defaultConfiguration
    }
    
    return configuration
}

// configures your application
public func configure(_ app: Application) async throws {
    app.asyncCommands.use(PresentationServiceCommand(), as: "present", isDefault: true)
    app.asyncCommands.use(ConfigurationCommand(), as: "configuration")
    
    // register routes
    try routes(app, configuration())
}
