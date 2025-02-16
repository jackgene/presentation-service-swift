@testable import App
@preconcurrency import SwiftCheck
import SwiftHamcrest
import XCTest

final class MultiSetTests: XCTestCase {
    let emptyInstance: MultiSet<String> = MultiSet(minimumCapacity: 2)
    
    // MARK: Specifications
    func testSpec_init_empty() {
        // Set up & Test
        let instance: MultiSet<String> = emptyInstance
        
        // Verify
        assertThat(instance.countsByElement, empty())
        assertThat(instance.elementsByCount, empty())
    }
    
    func testSpec_update_recordCorrectCounts() {
        // Set up
        var instance: MultiSet<String> = emptyInstance
        
        // Test
        instance.update(byAdding: "test-2", andRemoving: "test-1") // test-1: 0, test-2: 1
        instance.update(byAdding: "test-1")                        // test-1: 1, test-2: 1
        instance.update(byAdding: "test-2", andRemoving: "test-1") // test-1: 0, test-2: 2
        instance.update(byAdding: "test-1")                        // test-1: 1, test-2: 2
        instance.update(byAdding: "test-1")                        // test-1: 2, test-2: 2
        instance.update(byAdding: "test-2", andRemoving: "test-1") // test-1: 1, test-2: 3
        instance.update(byAdding: "test-1")                        // test-1: 2, test-2: 3
        instance.update(byAdding: "test-2", andRemoving: "test-1") // test-1: 1, test-2: 4
        instance.update(byAdding: "test-1")                        // test-1: 2, test-2: 4
        instance.update(byAdding: "test-2", andRemoving: "test-1") // test-1: 1, test-2: 5
        
        // Verify
        assertThat(instance.countsByElement, equalTo(["test-1": 1, "test-2": 5]))
        assertThat(instance.elementsByCount, equalTo([1: ["test-1"], 5: ["test-2"]]))
    }
    
    func testSpec_update_decrementZero() {
        // Set up
        var instance: MultiSet<String> = emptyInstance
        
        // Test
        instance.update(byAdding: "unused", andRemoving: "test")
        
        // Verify
        assertThat(instance.countsByElement["test"], nilValue())
    }
    
    func testSpec_update_incrementMax() {
        // Set up
        var instance: MultiSet<String> = emptyInstance
        instance.countsByElement["test"] = UInt.max
        instance.elementsByCount[UInt.max] = ["test"]
        
        // Test
        instance.update(byAdding: "test")
        
        // Verify
        assertThat(instance.countsByElement["test"], equalTo(UInt.max))
    }
    
    func testSpec_update_appendToItemsByCountWhenIncremented() {
        // Set up
        var instance: MultiSet<String> = emptyInstance
        instance.update(byAdding: "test-1")
        
        // Test
        instance.update(byAdding: "test-2")
        
        // Verify
        // Incremented value should be appended
        assertThat(instance.elementsByCount, equalTo([1: ["test-1", "test-2"]]))
    }
    
    func testSpec_update_prependToItemsByCountWhenDecremented() {
        // Set up
        var instance: MultiSet<String> = emptyInstance
        instance.update(byAdding: "test-2")
        instance.update(byAdding: "test-2")
        
        // Test
        instance.update(byAdding: "test-1", andRemoving: "test-2")
        
        // Verify
        // Decremented value should be prepended
        assertThat(instance.elementsByCount, equalTo([1: ["test-2", "test-1"]]))
    }
    
    func testSpec_update_omitZeroCounts() {
        // Set up
        var instance: MultiSet<String> = emptyInstance
        
        // Test
        instance.update(byAdding: "test", andRemoving: "test")
        
        // Verify
        assertThat(instance.countsByElement, hasCount(0))
        assertThat(instance.elementsByCount, hasCount(0))
    }
    
    // MARK: Properties
    static let duplicativeElements: Gen<[String]> = Gen<String>.alphabeticalLowercase
        .flatMap { (element: String) in
            Gen<Int>.positive.flatMap { (count: Int) in
                Gen.pure((element, count))
            }
        }
        .proliferate
        .suchThat { !$0.isEmpty }
        .map { (elementsAndCounts: [(String, Int)]) in
            elementsAndCounts
                .flatMap {
                    let (element, count): (String, Int) = $0
                    
                    return Array(repeating: element, count: count)
                }
                .shuffled()
        }
    
    func testProp_update_countsByElementAndElementsByCountMustReciprocate() {
        property(
            "counts by element and elements by counts must reciprocate",
            arguments: checkerArguments
        ) <- forAll(
            Self.duplicativeElements, Self.duplicativeElements
        ) { (increments: [String], decrements: [String]) in
            
            // Test
            var instance: MultiSet<String> = self.emptyInstance
            for increment in increments {
                instance.update(byAdding: increment)
            }
            for decrement in decrements {
                instance.update(byAdding: "placeholder", andRemoving: decrement)
            }
            
            // Verify
            return (
                instance.countsByElement.allSatisfy {
                    let element: String = $0.key
                    let count: UInt = $0.value
                    
                    return instance.elementsByCount[count]?.contains(element) ?? false
                }
                
                ^&&^
                
                instance.elementsByCount.allSatisfy {
                    let count: UInt = $0.key
                    let elements: [String] = $0.value
                    
                    return elements.allSatisfy { (element: String) in
                        instance.countsByElement[element] == count
                    }
                }
            )
        }
    }
    
    func testProp_update_neverRecordZeroCounts() {
        property(
            "never record zero counts",
            arguments: checkerArguments
        ) <- forAll(
            Self.duplicativeElements, Self.duplicativeElements
        ) { (increments: [String], decrements: [String]) in
            
            // Test
            var instance: MultiSet<String> = self.emptyInstance
            for increment in increments {
                instance.update(byAdding: increment)
            }
            for decrement in decrements {
                instance.update(byAdding: "placeholder", andRemoving: decrement)
            }
            
            // Verify
            return (
                instance.countsByElement.values.allSatisfy { $0 > 0 }
                
                ^&&^
                
                instance.elementsByCount.keys.allSatisfy { $0 > 0 }
            )
        }
    }
    
    func testProp_update_mostRecentlyIncrementedElementIsTheLastOfElementsByCount() {
        property(
            "most recently incremented element is the last of elements by count",
            arguments: checkerArguments
        ) <- forAll(
            Self.duplicativeElements
        ) { (elements: [String]) in
            
            // Set up
            var instance: MultiSet<String> = self.emptyInstance
            
            // Test
            let actualAssertions: [Bool] = elements
                .map { (element: String) in
                    instance.update(byAdding: element)
                    
                    guard let count: UInt = instance.countsByElement[element] else {
                        return false // can never increment to 0
                    }
                    guard let elements: [String] = instance.elementsByCount[count] else {
                        return false // if count exists, so should this
                    }
                    guard let lastOfElementsByCount: String = elements.last else {
                        return false // if elements exist, it should never be empty
                    }
                    return lastOfElementsByCount == element
                }
            
            // Verify
            return actualAssertions.allSatisfy { $0 }
        }
    }
    
    func testProp_update_mostRecentlyDecrementedElementIsTheFirstOfElementsByCount() {
        property(
            "most recently decremented element is the first of elements by count",
            arguments: checkerArguments
        ) <- forAll(
            Self.duplicativeElements
        ) { (elements: [String]) in
            
            // Set up
            var instance: MultiSet<String> = self.emptyInstance
            for element in elements {
                instance.update(byAdding: element)
            }
            
            // Test
            let actualAssertions: [Bool] = elements
                .map { (element: String) in
                    instance.update(byAdding: "placeholder", andRemoving: element)
                    
                    guard let count: UInt = instance.countsByElement[element] else {
                        return true // decremented to 0
                    }
                    guard let elements: [String] = instance.elementsByCount[count] else {
                        return false // if count exists, so should this
                    }
                    guard let firstOfElementsByCount: String = elements.first else {
                        return false // if elements exist, it should never be empty
                    }
                    return firstOfElementsByCount == element
                }
            
            // Verify
            return actualAssertions.allSatisfy { $0 }
        }
    }
    
    // MARK: Performance
    func testPerf_update_newVotePerformance() {
        var instance: MultiSet<String> = emptyInstance
        
        measure(metrics: [XCTClockMetric()]) {
            instance.update(byAdding: "test")
        }
    }
    
    func testPerf_update_voteChangePerformance() {
        var instance: MultiSet<String> = emptyInstance
        
        measure(metrics: [XCTClockMetric()]) {
            instance.update(byAdding: "new", andRemoving: "old")
        }
    }
}
