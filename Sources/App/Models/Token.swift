import Foundation

public typealias Tokenizer = (String) -> [String]

func mappedKeywordsTokenizer(_ keywordByToken: [String: String]) -> Tokenizer {
    { (text: String) in
        let normalizedWords: [String] = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(
                separatedBy: .whitespacesAndNewlines.union(CharacterSet(charactersIn: #"!"&,./?|"#))
            )
            .map { $0.lowercased() }
        return normalizedWords.compactMap { keywordByToken[$0] }
    }
}

func normalizedWordsTokenizer(stopWords: Set<String>, minWordLength: Int) -> Tokenizer {
    { (text: String) in
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .letters.union(CharacterSet(charactersIn: "-")).inverted)
            .filter { $0.count >= minWordLength && !stopWords.contains($0) }
            .map { $0.lowercased() }
    }
}
