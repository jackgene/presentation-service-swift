import Foundation

private let languagesByName: [String: String] = [
    // GoodRx Languages
    // Go
    "go": "Go",
    "golang": "Go",
    // Kotlin
    "kotlin": "Kotlin",
    "kt": "Kotlin",
    // Python
    "py": "Python",
    "python": "Python",
    // Swift
    "swift": "Swift",
    // TypeScript
    "ts": "TypeScript",
    "typescript": "TypeScript",
    
    // Others
    // C/C++
    "c": "C",
    "c++": "C",
    // C#
    "c#": "C#",
    "csharp": "C#",
    // Java
    "java": "Java",
    // Javascript
    "js": "JavaScript",
    "ecmascript": "JavaScript",
    "javascript": "JavaScript",
    // Lisp
    "lisp": "Lisp",
    "clojure": "Lisp",
    "racket": "Lisp",
    "scheme": "Lisp",
    // ML
    "ml": "ML",
    "haskell": "ML",
    "caml": "ML",
    "elm": "ML",
    "f#": "ML",
    "ocaml": "ML",
    "purescript": "ML",
    // Perl
    "perl": "Perl",
    // PHP
    "php": "PHP",
    // Ruby
    "ruby": "Ruby",
    "rb": "Ruby",
    // Rust
    "rust": "Rust",
    // Scala
    "scala": "Scala",
]

private func tokensFromWords(_ byName: [String: String], text: String) -> [String] {
    let normalizedWords: [String] = text
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .components(
            separatedBy: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "!,./"))
        )
        .map { $0.lowercased() }
    return normalizedWords.compactMap { byName[$0] }
}

func languagesFromWords(text: String) -> [String] {
    tokensFromWords(languagesByName, text: text)
}

private let minWordLength: Int = 3
private let englishStopWords: Set<String> = Set(
    arrayLiteral: "about",
    "above",
    "after",
    "again",
    "against",
    "all",
    "and",
    "any",
    "are",
    "because",
    "been",
    "before",
    "being",
    "below",
    "between",
    "both",
    "but",
    "can",
    "did",
    "does",
    "doing",
    "down",
    "during",
    "each",
    "few",
    "for",
    "from",
    "further",
    "had",
    "has",
    "have",
    "having",
    "her",
    "here",
    "hers",
    "herself",
    "him",
    "himself",
    "his",
    "how",
    "into",
    "its",
    "itself",
    "just",
    "me",
    "more",
    "most",
    "myself",
    "nor",
    "not",
    "now",
    "off",
    "once",
    "only",
    "other",
    "our",
    "ours",
    "ourselves",
    "out",
    "over",
    "own",
    "same",
    "she",
    "should",
    "some",
    "such",
    "than",
    "that",
    "the",
    "their",
    "theirs",
    "them",
    "themselves",
    "then",
    "there",
    "these",
    "they",
    "this",
    "those",
    "through",
    "too",
    "under",
    "until",
    "very",
    "was",
    "were",
    "what",
    "when",
    "where",
    "which",
    "while",
    "who",
    "whom",
    "why",
    "will",
    "with",
    "you",
    "your",
    "yours",
    "yourself",
    "yourselves"
)

func normalizedEnglishWords(text: String) -> [String] {
    text
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .components(separatedBy: .letters.union(CharacterSet(charactersIn: "-")).inverted)
        .filter { $0.count >= minWordLength && !englishStopWords.contains($0) }
        .map { $0.lowercased() }
}
