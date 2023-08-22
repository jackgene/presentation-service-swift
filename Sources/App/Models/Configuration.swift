import Foundation

struct Configuration: Codable {
    struct LanguagePoll: Codable {
        let maxVotesPerPerson: Int
        let languageByKeyword: [String: String]
        
        enum CodingKeys: String, CodingKey {
            case maxVotesPerPerson = "MaxVotesPerPerson"
            case languageByKeyword = "LanguageByKeyword"
        }
    }
    
    struct WordCloud: Codable {
        let maxWordsPerPerson: Int
        let minWordLength: Int
        let maxWordLength: Int
        let stopWords: Set<String>
        
        enum CodingKeys: String, CodingKey {
            case maxWordsPerPerson = "MaxWordsPerPerson"
            case minWordLength = "MinWordLength"
            case maxWordLength = "MaxWordLength"
            case stopWords = "StopWords"
        }
    }
    
    private static let plistDecoder: PropertyListDecoder = PropertyListDecoder()
    public static let defaultConfigurationPlist: String = #"""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>LanguagePoll</key>
            <dict>
                <key>MaxVotesPerPerson</key>
                <integer>1</integer>
                <key>LanguageByKeyword</key>
                <dict>
                    <!-- C/C++ -->
                    <key>c</key>
                    <string>C</string>
                    <key>c++</key>
                    <string>C</string>
                    
                    <!-- C# -->
                    <key>c#</key>
                    <string>C#</string>
                    <key>csharp</key>
                    <string>C#</string>
                    
                    <!-- Go -->
                    <key>go</key>
                    <string>Go</string>
                    <key>golang</key>
                    <string>Go</string>
                    
                    <!-- Java -->
                    <key>java</key>
                    <string>Java</string>
                    
                    <!-- Javascript -->
                    <key>js</key>
                    <string>JavaScript</string>
                    <key>ecmascript</key>
                    <string>JavaScript</string>
                    <key>javascript</key>
                    <string>JavaScript</string>
                    
                    <!-- Kotlin -->
                    <key>kotlin</key>
                    <string>Kotlin</string>
                    <key>kt</key>
                    <string>Kotlin</string>
                    
                    <!-- Lisp -->
                    <key>lisp</key>
                    <string>Lisp</string>
                    <key>clojure</key>
                    <string>Lisp</string>
                    <key>racket</key>
                    <string>Lisp</string>
                    <key>scheme</key>
                    <string>Lisp</string>
                    
                    <!-- ML -->
                    <key>ml</key>
                    <string>ML</string>
                    <key>haskell</key>
                    <string>ML</string>
                    <key>caml</key>
                    <string>ML</string>
                    <key>elm</key>
                    <string>ML</string>
                    <key>f#</key>
                    <string>ML</string>
                    <key>ocaml</key>
                    <string>ML</string>
                    <key>purescript</key>
                    <string>ML</string>
                    
                    <!-- Perl -->
                    <key>perl</key>
                    <string>Perl</string>
                    
                    <!-- PHP -->
                    <key>php</key>
                    <string>PHP</string>
                    
                    <!-- Python -->
                    <key>py</key>
                    <string>Python</string>
                    <key>python</key>
                    <string>Python</string>
                    
                    <!-- Ruby -->
                    <key>ruby</key>
                    <string>Ruby</string>
                    <key>rb</key>
                    <string>Ruby</string>
                    
                    <!-- Rust -->
                    <key>rust</key>
                    <string>Rust</string>
                    
                    <!-- Scala -->
                    <key>scala</key>
                    <string>Scala</string>
                    
                    <!-- Swift -->
                    <key>swift</key>
                    <string>Swift</string>
                    
                    <!-- TypeScript -->
                    <key>ts</key>
                    <string>TypeScript</string>
                    <key>typescript</key>
                    <string>TypeScript</string>
                </dict>
            </dict>
            <key>WordCloud</key>
            <dict>
                <key>MaxWordsPerPerson</key>
                <integer>7</integer>
                <key>MinWordLength</key>
                <integer>3</integer>
                <key>MaxWordLength</key>
                <integer>24</integer>
                <key>StopWords</key>
                <array>
                    <string>about</string>
                    <string>above</string>
                    <string>after</string>
                    <string>again</string>
                    <string>against</string>
                    <string>all</string>
                    <string>and</string>
                    <string>any</string>
                    <string>are</string>
                    <string>because</string>
                    <string>been</string>
                    <string>before</string>
                    <string>being</string>
                    <string>below</string>
                    <string>between</string>
                    <string>both</string>
                    <string>but</string>
                    <string>can</string>
                    <string>did</string>
                    <string>does</string>
                    <string>doing</string>
                    <string>down</string>
                    <string>during</string>
                    <string>each</string>
                    <string>few</string>
                    <string>for</string>
                    <string>from</string>
                    <string>further</string>
                    <string>had</string>
                    <string>has</string>
                    <string>have</string>
                    <string>having</string>
                    <string>her</string>
                    <string>here</string>
                    <string>hers</string>
                    <string>herself</string>
                    <string>him</string>
                    <string>himself</string>
                    <string>his</string>
                    <string>how</string>
                    <string>into</string>
                    <string>its</string>
                    <string>itself</string>
                    <string>just</string>
                    <string>me</string>
                    <string>more</string>
                    <string>most</string>
                    <string>myself</string>
                    <string>nor</string>
                    <string>not</string>
                    <string>now</string>
                    <string>off</string>
                    <string>once</string>
                    <string>only</string>
                    <string>other</string>
                    <string>our</string>
                    <string>ours</string>
                    <string>ourselves</string>
                    <string>out</string>
                    <string>over</string>
                    <string>own</string>
                    <string>same</string>
                    <string>she</string>
                    <string>should</string>
                    <string>some</string>
                    <string>such</string>
                    <string>than</string>
                    <string>that</string>
                    <string>the</string>
                    <string>their</string>
                    <string>theirs</string>
                    <string>them</string>
                    <string>themselves</string>
                    <string>then</string>
                    <string>there</string>
                    <string>these</string>
                    <string>they</string>
                    <string>this</string>
                    <string>those</string>
                    <string>through</string>
                    <string>too</string>
                    <string>under</string>
                    <string>until</string>
                    <string>very</string>
                    <string>was</string>
                    <string>were</string>
                    <string>what</string>
                    <string>when</string>
                    <string>where</string>
                    <string>which</string>
                    <string>while</string>
                    <string>who</string>
                    <string>whom</string>
                    <string>why</string>
                    <string>will</string>
                    <string>with</string>
                    <string>you</string>
                    <string>your</string>
                    <string>yours</string>
                    <string>yourself</string>
                    <string>yourselves</string>
                </array>
            </dict>
        </dict>
        </plist>

        """#
    public static let defaultConfiguration: Configuration = try! plistDecoder.decode(
        Self.self, from: defaultConfigurationPlist.data(using: .utf8)!
    )
    
    static func load(fromPlist url: URL) throws -> Configuration {
        let data = try Data(contentsOf: url)
        return try Self.plistDecoder.decode(Self.self, from: data)
    }

    let languagePoll: LanguagePoll
    let wordCloud: WordCloud
    
    enum CodingKeys: String, CodingKey {
        case languagePoll = "LanguagePoll"
        case wordCloud = "WordCloud"
    }
}
