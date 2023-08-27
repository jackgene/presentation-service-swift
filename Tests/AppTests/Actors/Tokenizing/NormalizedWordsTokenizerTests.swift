@testable import App
import SwiftCheck
import SwiftHamcrest
import XCTest

final class NormalizedWordsTokenizerTests: XCTestCase {
    static let testAsciiText: String = "#hashtag hyphenated-word-  invalid_symbols?! YOLO Yo!fomo"
    static let testUnicodeText: String = "Schrödinger's smol little 🐱 (小猫)!"
    static let testWordLengthText: String = "i am not your large teapot"
    static let testInputText: [String] = [testAsciiText, testUnicodeText, testWordLengthText]
    
    // MARK: Specifications
    func testSpec_tokenize_withNoStopWordsMinimumOrMaximumWordLength() throws {
        // Set up
        let instance = try NormalizedWordsTokenizer()
        let expectedTokensSet: [[String]] = [
            [
                "hashtag",          // # is not valid (considered whitespace)
                "hyphenated-word",  // - is valid
                "invalid",          // _ is not valid (considered whitespace)
                "symbols",          // ? and ! are not valid (consider whitespace)
                "yolo",             // lower-cased
                "yo",               // ! is not valid (considered whitespace)
                "fomo",             // after !
            ],
            [
                "schrödinger",  // ' is not valid (considered whitespace)
                "s",
                "smol",
                "little",       // 🐱 is not valid (considered whitespace)
                "小猫",          // () are not valid (considered whitespace)
            ],
            ["i", "am", "not", "your", "large", "teapot"]
        ]
        
        // Test
        let actualTokensSet: [[String]] = Self.testInputText.map { instance.tokenize($0)}
        
        for (expectedTokens, actualTokens) in zip(expectedTokensSet, actualTokensSet) {
            assertThat(actualTokens, equalTo(expectedTokens))
        }
    }
    
    func testSpec_tokenize_withNoStopWordsMinimumWordLength3NoMaximumWordLength() throws {
        // Set up
        let instance = try NormalizedWordsTokenizer(minWordLength: 3)
        let expectedTokensSet: [[String]] = [
            [
                "hashtag",
                "hyphenated-word",
                "invalid",
                "symbols",
                "yolo",
                // "yo", too short
                "fomo",
            ],
            [
                "schrödinger",
                // "s",   too short
                "smol",
                "little",
                // "🐱"   not a letter
                // "小猫"  too short
            ],
            ["not", "your", "large", "teapot"]
        ]
        
        // Test
        let actualTokensSet: [[String]] = Self.testInputText.map { instance.tokenize($0)}
        
        for (expectedTokens, actualTokens) in zip(expectedTokensSet, actualTokensSet) {
            assertThat(actualTokens, equalTo(expectedTokens))
        }
    }
    
    func testSpec_tokenize_withNoStopWordsNoMinimumWordLengthAndMaximumWordLength4() throws {
        // Set up
        let instance = try NormalizedWordsTokenizer(maxWordLength: 4)
        let expectedTokensSet: [[String]] = [
            [
                // "hashtag",         too long
                // "hyphenated-word", too long
                // "invalid",         too long
                // "symbols",         too long
                "yolo",
                "yo",
                "fomo",
            ],
            [
                // "schrödinger",  too long
                "s",
                "smol",
                // "little",       too long
                // "🐱"            not a letter
                "小猫"
            ],
            ["i", "am", "not", "your"]
        ]
        
        // Test
        let actualTokensSet: [[String]] = Self.testInputText.map { instance.tokenize($0)}
        
        for (expectedTokens, actualTokens) in zip(expectedTokensSet, actualTokensSet) {
            assertThat(actualTokens, equalTo(expectedTokens))
        }
    }
    
    func testSpec_tokenize_withStopWordsNoMinimumOrMaximumWordLength() throws {
        // Set up
        let instance = try NormalizedWordsTokenizer(stopWords: ["yolo", "large", "schrödinger"])
        let expectedTokensSet: [[String]] = [
            [
                "hashtag",
                "hyphenated-word",
                "invalid",
                "symbols",
                // "yolo", stop word
                "yo",
                "fomo",
            ],
            [
                //"schrödinger",  stop word
                "s",
                "smol",
                "little",
                // "🐱"           not a letter
                "小猫",
            ],
            ["i", "am", "not", "your", "teapot"]
        ]
        
        // Test
        let actualTokensSet: [[String]] = Self.testInputText.map { instance.tokenize($0)}
        
        for (expectedTokens, actualTokens) in zip(expectedTokensSet, actualTokensSet) {
            assertThat(actualTokens, equalTo(expectedTokens))
        }
    }
    
    func testSpec_tokenize_withStopWordsMinimumWordLength3AndMaximumWordLength5() throws {
        // Set up
        let instance = try NormalizedWordsTokenizer(
            stopWords: ["yolo", "large", "schrödinger"],
            minWordLength: 3,
            maxWordLength: 5
        )
        let expectedTokensSet: [[String]] = [
            [
                // "hashtag",          too long
                // "hyphenated-word",  too long
                // "invalid",          too long
                // "symbols",          too long
                // "yolo",             stop word
                // "yo",               too short
                "fomo",
            ],
            [
                // "schrödinger",  stop word
                // "s",            too short
                "smol",
                // "little",       too long
                // "🐱"            not a letter
                // "小猫"           too short
            ],
            ["not", "your"]
        ]
        
        // Test
        let actualTokensSet: [[String]] = Self.testInputText.map { instance.tokenize($0)}
        
        for (expectedTokens, actualTokens) in zip(expectedTokensSet, actualTokensSet) {
            assertThat(actualTokens, equalTo(expectedTokens))
        }
    }
    
    func testSpec_init_withEmptyStringStopWord() {
        // Test & Verify
        assertThrows(try NormalizedWordsTokenizer(stopWords: [""]))
    }
    
    func testSpec_init_withBlankStringStopWord() {
        // Test & Verify
        assertThrows(try NormalizedWordsTokenizer(stopWords: [" "]))
    }
    
    func testSpec_init_withNumericStopWord() {
        // Test & Verify
        assertThrows(try NormalizedWordsTokenizer(stopWords: ["1"]))
    }
    
    func testSpec_init_withNonLetterStopWord() {
        // Test & Verify
        assertThrows(try NormalizedWordsTokenizer(stopWords: ["$_"]))
    }
    
    func testSpec_init_withMinimumWordLengthLessThan1() {
        // Test & Verify
        assertThrows(try NormalizedWordsTokenizer(minWordLength: 0))
    }
    
    func testSpec_init_withMaximumWordLengthLessThanMinimumWordLength() {
        // Test & Verify
        assertThrows(try NormalizedWordsTokenizer(minWordLength: 5, maxWordLength: 4))
    }
    
    // MARK: Properties
    func testProp_tokenize_onlyExtractHyphenatedLowerCaseTokens() {
        property("only extract hyphenated lower-case tokens") <- forAll { (text: String) in
            
            // Set up
            let instance = try NormalizedWordsTokenizer()
            
            // Test
            let actualTokens: [String] = instance.tokenize(text)
            
            // Verify
            return actualTokens.allSatisfy {
                $0.allSatisfy { $0.isLowercase || $0 == "-" }
            }
        }
    }
    
    func testProp_tokenize_neverExtractStopWords() {
        property("never extract stop words") <- forAll(
            Gen<String>.alphabeticalLowercase
                .suchThat { !$0.isEmpty }
                .proliferate
                .suchThat { !$0.isEmpty }
                .map { Set($0) },
            String.arbitrary
        ) { (stopWords: Set<String>, text: String) in
            
            // Set up
            let instance = try NormalizedWordsTokenizer(stopWords: stopWords)
            
            // Test
            let actualTokens: [String] = instance.tokenize(text)
            
            // Verify
            return actualTokens.allSatisfy { !stopWords.contains($0) }
        }
    }
    
    func testProp_tokenize_onlyExtractWordsLongerThanMinWordLength() {
        property("only extract words longer than minWordLength") <- forAll(
            Gen<Int>.positive,
            String.arbitrary
        ) { (minWordLength: Int, text: String) in
            
            // Set up
            let instance = try NormalizedWordsTokenizer(minWordLength: minWordLength)
            
            // Test
            let actualTokens: [String] = instance.tokenize(text)
            
            // Verify
            return actualTokens.allSatisfy { $0.count >= minWordLength }
        }
    }
    
    func testProp_tokenize_onlyExtractWordsShorterThanMaxWordLength() {
        property("only extract words shorter than maxWordLength") <- forAll(
            Gen<Int>.positive,
            String.arbitrary
        ) { (maxWordLength: Int, text: String) in
            
            // Set up
            let instance = try NormalizedWordsTokenizer(maxWordLength: maxWordLength)
            
            // Test
            let actualTokens: [String] = instance.tokenize(text)
            
            // Verify
            return actualTokens.allSatisfy { $0.count <= maxWordLength }
        }
    }
}
