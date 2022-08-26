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

func tokenFromFirstWord(_ byName: [String: String], text: String) -> String? {
    let normalizedFirstWord: String? = text
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .components(
            separatedBy: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "!,./"))
        )
        .first?.lowercased()
    return normalizedFirstWord.flatMap { byName[$0] }
}

let languageFromFirstWord: (String) -> String? = {
    tokenFromFirstWord(languagesByName, text: $0)
}

