@testable import App
@preconcurrency import SwiftCheck
import SwiftHamcrest
import XCTest

final class MappedKeywordsTokenizerTests: XCTestCase {
    let testText: String = "Lorem ipsum dolor sit amet!"
    
    // MARK: Specifications
    func testSpec_tokenize_withLowerCaseKeyedMapping() throws {
        // Set up
        let instance = try MappedKeywordsTokenizer(
            keywordsByRawToken: [
                "lorem": "Mock-1",
                "ipsum": "Mock-1",
                "amet": "Mock-2",
                "other": "Mock-2",
            ]
        )
        
        // Test
        let actualTokens: [String] = instance.tokenize(testText)
        
        // Verify
        let expectedTokens: [String] = ["Mock-1", "Mock-1", "Mock-2"]
        assertThat(actualTokens, equalTo(expectedTokens))
    }
    
    func testSpec_tokenize_withUpperCaseKeyedMapping() throws {
        // Set up
        let instance = try MappedKeywordsTokenizer(
            keywordsByRawToken: [
                "LOREM": "Mock-1",
                "IPSUM": "Mock-1",
                "AMET": "Mock-2",
                "OTHER": "Mock-2",
            ]
        )
        
        // Test
        let actualTokens: [String] = instance.tokenize(testText)
        
        // Verify
        let expectedTokens: [String] = ["Mock-1", "Mock-1", "Mock-2"]
        assertThat(actualTokens, equalTo(expectedTokens))
    }
    
    func testSpec_init_withEmptyMapping() {
        // Test & Verify
        assertThrows(try MappedKeywordsTokenizer(keywordsByRawToken: [:]))
    }
    
    func testSpec_init_withSpaceInMapping() {
        // Test & Verify
        assertThrows(try MappedKeywordsTokenizer(keywordsByRawToken: ["mock token": "whatever"]))
    }
    
    func testSpec_init_withTabInMapping() {
        // Test & Verify
        assertThrows(try MappedKeywordsTokenizer(keywordsByRawToken: ["mock\ttoken": "whatever"]))
    }
    
    func testSpec_init_withExclamationMarkInMapping() {
        // Test & Verify
        assertThrows(try MappedKeywordsTokenizer(keywordsByRawToken: ["mock!token": "whatever"]))
    }
    
    func testSpec_init_withQuoteInMapping() {
        // Test & Verify
        assertThrows(try MappedKeywordsTokenizer(keywordsByRawToken: [#"mock"token"#: "whatever"]))
    }
    
    func testSpec_init_withAmpersandInMapping() {
        // Test & Verify
        assertThrows(try MappedKeywordsTokenizer(keywordsByRawToken: ["mock&token": "whatever"]))
    }
    
    func testSpec_init_withCommaInMapping() {
        // Test & Verify
        assertThrows(try MappedKeywordsTokenizer(keywordsByRawToken: ["mock,token": "whatever"]))
    }
    
    func testSpec_init_withPeriodInMapping() {
        // Test & Verify
        assertThrows(try MappedKeywordsTokenizer(keywordsByRawToken: ["mock.token": "whatever"]))
    }
    
    func testSpec_init_withSlashInMapping() {
        // Test & Verify
        assertThrows(try MappedKeywordsTokenizer(keywordsByRawToken: ["mock/token": "whatever"]))
    }
    
    func testSpec_init_withQuestionMarkInMapping() {
        // Test & Verify
        assertThrows(try MappedKeywordsTokenizer(keywordsByRawToken: ["mock?token": "whatever"]))
    }
    
    func testSpec_init_withPipeInMapping() {
        // Test & Verify
        assertThrows(try MappedKeywordsTokenizer(keywordsByRawToken: ["mock|token": "whatever"]))
    }
    
    // MARK: Properties
    static let keywordsByRawToken: Gen<[String: String]> = Gen<String>.alphabeticalLowercase
        .suchThat { $0.count > 0 }.proliferate
        .flatMap { (k : [String]) in
            [String].arbitrary.flatMap { (v : [String]) in
                Gen.pure(Dictionary(uniqueKeysWithValues: zip(k.uniqued(), v)))
            }
        }
        .suchThat { !$0.isEmpty }
    
    func testProp_tokenize_extractAllMappedTokens() {
        property(
            "extract all mapped tokens",
            arguments: checkerArguments
        ) <- forAll(
            Self.keywordsByRawToken
        ) {
            (keywordsByRawToken: [String: String]) in
            
            // Set up
            let instance: MappedKeywordsTokenizer = try MappedKeywordsTokenizer(
                keywordsByRawToken: keywordsByRawToken
            )
            
            // Test
            let actualTokens: [String] = instance
                .tokenize(instance.keywordsByRawToken.keys.joined(separator: " "))
            
            // Verify
            return Set(actualTokens) == Set(instance.keywordsByRawToken.values)
        }
    }
    
    func testProp_tokenize_onlyExtractMappedTokens() {
        property(
            "extract all mapped tokens",
            arguments: checkerArguments
        ) <- forAll(
            Self.keywordsByRawToken,
            Gen.alphabeticalLowercase
        ) {
            (keywordsByRawToken: [String: String], text: String) in
            
            // Set up
            let instance: MappedKeywordsTokenizer = try MappedKeywordsTokenizer(
                keywordsByRawToken: keywordsByRawToken
            )
            
            // Test
            let actualTokens: [String] = instance.tokenize(text)
            
            // Verify
            return Set(actualTokens).isSubset(of: instance.keywordsByRawToken.values)
        }
    }
}
