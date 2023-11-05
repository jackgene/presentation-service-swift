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
            let executableURL: URL = Bundle.main.executableURL
        else {
            print("Unable to determine executable location", to: &stderr)
            exit(100)
        }
        let url: URL = executableURL.deletingLastPathComponent().appending(path: "presentation-service.plist")
        if signature.write {
            if signature.overwrite || !FileManager.default.fileExists(atPath: url.path) {
                do {
                    try Configuration.defaultConfigurationPlist.write(
                        to: url, atomically: false, encoding: .utf8
                    )
                } catch {
                    print("Error writing presentation-service.plist: \(error.localizedDescription)", to: &stderr)
                    exit(2)
                }
            } else {
                print("Existing presentation-service.plist found. -f to overwrite.", to: &stderr)
                exit(1)
            }
        } else {
            if
                let plist: String = try? String(contentsOf: url),
                plist != ""
            {
                print("Existing presentation-service.plist found:\n", to: &stderr)
                print(plist)
            } else {
                print("No existing presentation-service.plist. Using defaults:\n", to: &stderr)
                print(Configuration.defaultConfigurationPlist)
            }
        }
    }
}
