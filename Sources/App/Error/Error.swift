/// Application errors
public enum Error: Swift.Error {
    case initializationError(reason: String)
    case illegalArgument(reason: String)
}
