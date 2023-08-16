import Vapor

func configuration() -> Configuration {
    guard
        let url: URL = Bundle.main.url(forResource: "presentation-service", withExtension: "plist"),
        let configuration: Configuration = try? Configuration.load(fromPlist: url)
    else {
        return Configuration.defaultConfiguration
    }
    
    return configuration
}

// configures your application
public func configure(_ app: Application) throws {
    app.commands.use(PresentationServiceCommand(), as: "present", isDefault: true)
    app.commands.use(ConfigurationCommand(), as: "configuration")

    // register routes
    try routes(app, configuration())
}
