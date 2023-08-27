import Foundation

struct MappedKeywordsTokenizer {
    static let WordSeparators: CharacterSet =
        .whitespacesAndNewlines.union(CharacterSet(charactersIn: #"!"&,./?|"#))
    let keywordsByRawToken: [String: String]
    
    init(keywordsByRawToken: [String: String]) throws {
        guard !keywordsByRawToken.isEmpty else {
            throw Error.illegalArgument(reason: "keywordsByRawToken must not be empty")
        }
        let invalidRawTokens: [String] = keywordsByRawToken.keys
            .filter {
                $0.rangeOfCharacter(from: Self.WordSeparators) != nil
            }
        guard invalidRawTokens.isEmpty else {
            throw Error.illegalArgument(
                reason: "some keyword mappings have invalid raw tokens: {\(invalidRawTokens.joined(separator: ","))}"
            )
        }
        
        self.keywordsByRawToken = Dictionary(
            uniqueKeysWithValues: keywordsByRawToken.map { ($0.lowercased(), $1) }
        )
    }
    
    func tokenize(_ text: String) -> [String] {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: Self.WordSeparators)
            .map { $0.lowercased() }
            .compactMap { keywordsByRawToken[$0] }
    }
}
