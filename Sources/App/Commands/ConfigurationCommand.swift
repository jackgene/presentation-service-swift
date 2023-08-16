import ConsoleKit
import Foundation

/// Displays the current configuration.
public final class ConfigurationCommand: Command {
    public struct Signature: CommandSignature {
        public init() { }
    }

    public var help: String {
        return "Displays the current configuration as a PList."
    }

    init() { }

    public func run(using context: CommandContext, signature: Signature) throws {
        if
            let url: URL = Bundle.main.url(forResource: "presentation-service", withExtension: "plist"),
            let plist: String = try? String(contentsOf: url),
            plist != ""
        {
            print(plist)
        } else {
            print(Configuration.defaultConfigurationPlist)
        }
    }
}
