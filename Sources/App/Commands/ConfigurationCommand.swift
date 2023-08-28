import ConsoleKit
import Foundation

/// Displays the current configuration.
public final class ConfigurationCommand: Command {
    public struct Signature: CommandSignature {
        @Flag(name: "write", short: "w", help: "Write default configuration to presentation-service.plist.")
        var write: Bool
        
        @Flag(name: "force", short: "f", help: "Overwrite existing configuration file.")
        var overwrite: Bool
        
        public init() { }
    }
    
    public var help: String {
        return "Displays the current configuration as a PList."
    }
    
    init() { }
    
    public func run(using context: CommandContext, signature: Signature) throws {
        guard
            let url: URL = Bundle.main.url(forResource: "presentation-service", withExtension: "plist")
        else {
            "Unable to determine presentation-service.plist location\n"
                .data(using: .utf8)
                .map(FileHandle.standardError.write)
            exit(100)
        }
        if signature.write {
            if signature.overwrite || !FileManager.default.fileExists(atPath: url.path) {
                do {
                    try Configuration.defaultConfigurationPlist.write(
                        to: url, atomically: false, encoding: .utf8
                    )
                } catch {
                    "Error writing presentation-service.plist: \(error.localizedDescription)\n"
                        .data(using: .utf8)
                        .map(FileHandle.standardError.write)
                    exit(2)
                }
            } else {
                "Existing presentation-service.plist found. -f to overwrite.\n"
                    .data(using: .utf8)
                    .map(FileHandle.standardError.write)
                exit(1)
            }
        } else {
            if
                let plist: String = try? String(contentsOf: url),
                plist != ""
            {
                "Existing presentation-service.plist found:\n\n"
                    .data(using: .utf8)
                    .map(FileHandle.standardError.write)
                print(plist)
            } else {
                "No existing presentation-service.plist. Using defaults:\n\n"
                    .data(using: .utf8)
                    .map(FileHandle.standardError.write)
                print(Configuration.defaultConfigurationPlist)
            }
        }
    }
}
