import Foundation

struct NormalizedWordsTokenizer {
    static let ValidWordPattern: Regex = /(\p{L}+(?:-\p{L}+)*)/
    static let WordSeparators: CharacterSet =
        .letters.union(CharacterSet(charactersIn: "-")).inverted
    let stopWords: Set<String>
    let minWordLength: Int
    let maxWordLength: Int
    
    init(stopWords: Set<String>, minWordLength: Int, maxWordLength: Int) throws {
        guard minWordLength >= 1 else {
            throw Error.illegalArgument(
                reason: "minWordLength \(minWordLength) must be at least 1"
            )
        }
        guard maxWordLength >= minWordLength else {
            throw Error.illegalArgument(
                reason: "maxWordLength \(maxWordLength) must be no less than minWordLength \(minWordLength)"
            )
        }
        
        self.stopWords = stopWords
        self.minWordLength = minWordLength
        self.maxWordLength = maxWordLength
    }
    
    func tokenize(_ text: String) -> [String] {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: Self.WordSeparators)
            .map { $0.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "-")) }
            .filter {
                minWordLength...maxWordLength ~= $0.count &&
                !stopWords.contains($0) &&
                nil != (try? Self.ValidWordPattern.wholeMatch(in: $0))
            }
    }
}
