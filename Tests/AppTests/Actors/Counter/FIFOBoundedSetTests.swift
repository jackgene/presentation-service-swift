@testable import App
import SwiftCheck
import SwiftHamcrest
import XCTest

final class FIFOBoundedSetTests: XCTestCase {
    // MARK: Specifications
    var emptyStringSet: FIFOBoundedSet<String> {
        get throws { try FIFOBoundedSet<String>(maximumCount: 2) }
    }
    
    func testSpec_init_empty() throws {
        // Set up & Test
        let instance: FIFOBoundedSet<String> = try FIFOBoundedSet(maximumCount: 2)
        
        // Verify
        assertThat(instance, empty())
    }
    
    func testSpec_init_zeroMaximumCount() {
        // Test & Verify
        assertThrows(try FIFOBoundedSet<String>(maximumCount: 0))
    }
    
    func testSpec_append_newElementToEmptyInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        
        // Test
        let actualEffect: FIFOBoundedSet<String>.Effect? = instance.append("test")
        
        // Verify
        assertThat(actualEffect, equalTo(.appended(element: "test")))
        assertThat(instance.insertionOrder, equalTo(["test"]))
    }
    
    func testSpec_append_newElementToPartiallyFilledInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        _ = instance.append(contentsOf: ["test-1"])
        
        // Test
        let actualEffect: FIFOBoundedSet<String>.Effect? = instance.append("test-2")
        
        // Verify
        assertThat(actualEffect, equalTo(.appended(element: "test-2")))
        assertThat(instance.insertionOrder, equalTo(["test-1", "test-2"]))
    }
    
    func testSpec_append_existingElementToPartiallyFilledInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        _ = instance.append(contentsOf: ["test"])
        
        // Test
        let actualEffect: FIFOBoundedSet<String>.Effect? = instance.append("test")
        
        // Verify
        assertThat(actualEffect, nilValue())
        assertThat(instance.insertionOrder, equalTo(["test"]))
    }
    
    func testSpec_append_newElementToFullInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        _ = instance.append(contentsOf: ["test-1", "test-2"])
        
        // Test
        let actualEffect: FIFOBoundedSet<String>.Effect? = instance.append("test-3")
        
        // Verify
        assertThat(
            actualEffect,
            equalTo(.appendedEvicting(element: "test-3", evicting: "test-1"))
        )
        assertThat(instance.insertionOrder, equalTo(["test-2", "test-3"]))
    }
    
    func testSpec_append_existingElementToFullInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        _ = instance.append(contentsOf: ["test-1", "test-2"])
        
        // Test
        let actualEffect: FIFOBoundedSet<String>.Effect? = instance.append("test-1")
        
        // Verify
        assertThat(actualEffect, nilValue())
        assertThat(instance.insertionOrder, equalTo(["test-2", "test-1"]))
    }
    
    func testSpec_appendContentOf_newElementsToEmptyInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        
        // Test
        let actualEffects: [FIFOBoundedSet<String>.Effect] = instance
            .append(contentsOf: ["test-1", "test-2"])
        
        // Verify
        assertThat(
            actualEffects,
            equalTo([.appended(element: "test-1"), .appended(element: "test-2")])
        )
        assertThat(instance.insertionOrder, equalTo(["test-1", "test-2"]))
    }
    
    func testSpec_appendContentOf_sameElementsToEmptyInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        
        // Test
        let actualEffects: [FIFOBoundedSet<String>.Effect] = instance
            .append(contentsOf: ["test", "test"])
        
        // Verify
        assertThat(actualEffects, equalTo([.appended(element: "test")]))
        assertThat(instance.insertionOrder, equalTo(["test"]))
    }
    
    func testSpec_appendContentOf_newElementsToPartiallyFilledInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        _ = instance.append(contentsOf: ["test-1"])
        
        // Test
        let actualEffects: [FIFOBoundedSet<String>.Effect] = instance
            .append(contentsOf: ["test-2", "test-3"])
        
        // Verify
        assertThat(
            actualEffects,
            equalTo(
                [
                    .appended(element: "test-2"),
                    .appendedEvicting(element: "test-3", evicting: "test-1")
                ]
            )
        )
        assertThat(instance.insertionOrder, equalTo(["test-2", "test-3"]))
    }
    
    func testSpec_appendContentOf_existingAndNewElementsToFullInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        _ = instance.append(contentsOf: ["test-1", "test-2"])
        
        // Test
        let actualEffects: [FIFOBoundedSet<String>.Effect] = instance
            .append(contentsOf: ["test-1", "test-3"])
        
        // Verify
        assertThat(
            actualEffects,
            equalTo([.appendedEvicting(element: "test-3", evicting: "test-2")])
        )
        assertThat(instance.insertionOrder, equalTo(["test-1", "test-3"]))
    }
    
    func testSpec_appendContentOf_tooManyNewElementsToFullInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        _ = instance.append(contentsOf: ["test-1", "test-2"])
        
        // Test
        let actualEffects: [FIFOBoundedSet<String>.Effect] = instance
            .append(
                contentsOf: [
                    "test-3", "test-4", // skipped - overwritten
                    "test-5", "test-6"  // evicts test-1, test-2
                ]
            )
        
        // Verify
        assertThat(
            actualEffects,
            equalTo(
                [
                    .appendedEvicting(element: "test-5", evicting: "test-1"),
                    .appendedEvicting(element: "test-6", evicting: "test-2")
                ]
            )
        )
        assertThat(instance.insertionOrder, equalTo(["test-5", "test-6"]))
    }
    
    func testSpec_appendContentOf_existingElementsAfterNewElementsToFullInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        _ = instance.append(contentsOf: ["test-1", "test-2"])
        
        // Test
        let actualEffects: [FIFOBoundedSet<String>.Effect] = instance
            .append(
                contentsOf: [
                    "test-3", "test-4", // skipped - overwritten
                    "test-1", "test-2"  // skipped - identical to existing
                ]
            )
        
        // Verify
        assertThat(actualEffects, empty())
        assertThat(instance.insertionOrder, equalTo(["test-1", "test-2"]))
    }
    
    // MARK: Properties
    func testProp_appendContentOf_neverContainMoreElementsThanMaximumCount() {
        property(
            "never contain more elements than maximumCount",
            arguments: checkerArguments
        ) <- forAll(
            Gen<Int>.positive, [Int].arbitrary
        ) { (maximumCount: Int, elements: [Int]) in
            
            // Set up
            var instance: FIFOBoundedSet<Int> = try FIFOBoundedSet(maximumCount: maximumCount)
            
            // Test
            _ = instance.append(contentsOf: elements)
            
            // Verify
            return instance.count <= maximumCount
        }
    }
    
    func testProp_appendContentOf_alwaysIncludeTheMostRecentlyAddedElements() {
        property(
            "always include the most recently added elements",
            arguments: checkerArguments
        ) <- forAll(
            Gen<Int>.positive, [Int].arbitrary
        ) { (maximumCount: Int, elements: [Int]) in
            
            // Set up
            var instance: FIFOBoundedSet<Int> = try FIFOBoundedSet(maximumCount: maximumCount)
            
            // Test
            _ = instance.append(contentsOf: elements)
            
            // Verify
            return Set(elements.suffix(maximumCount)).isSubset(of: instance)
        }
    }
    
    func testProp_appendContentOf_onlyEvictTheLeastRecentlyAddedElements() {
        property(
            "only evict the least recently added elements",
            arguments: checkerArguments
        ) <- forAll(
            Gen<Int>.positive, [Int].arbitrary
        ) { (maximumCount: Int, elements: [Int]) in
            
            // Set up
            var instance: FIFOBoundedSet<Int> = try FIFOBoundedSet(maximumCount: maximumCount)
            
            // Test
            let actualEvictions: [Int] = instance.append(contentsOf: elements)
                .compactMap {
                    switch $0 {
                    case .appendedEvicting(_, let value): return value
                    case .appended: return nil
                    }
                }
            
            // Verify
            return Set(actualEvictions).isSubset(of: elements.dropLast(maximumCount))
        }
    }
    
    func testProp_appendContentOf_neverEvictWhenNotFull() {
        property(
            "never evict when not full",
            arguments: checkerArguments
        ) <- forAll(
            [Int].arbitrary.suchThat { !$0.isEmpty }
        ) { (elements: [Int]) in
            
            // Set up
            var instance: FIFOBoundedSet<Int> = try FIFOBoundedSet(maximumCount: elements.count)
            
            // Test
            let actualEvictions: [Int] = instance.append(contentsOf: elements)
                .compactMap {
                    switch $0 {
                    case .appendedEvicting(_, let value): return value
                    case .appended: return nil
                    }
                }
            
            // Verify
            return actualEvictions.isEmpty ^&&^ Set(instance) == Set(elements)
        }
    }
    
    func testProp_appendContentOf_appendAndAppendContentsOfAreEqualGivenIdenticalInput() {
        property(
            "append and appendContentOf are equal given identical input",
            arguments: checkerArguments
        ) <- forAll(
            Gen<Int>.positive, [Int].arbitrary
        ) { (maximumCount: Int, elements: [Int]) in
            
            // Set up
            let empty: FIFOBoundedSet<Int> = try FIFOBoundedSet(maximumCount: maximumCount)
            var instanceUsingAppend: FIFOBoundedSet<Int> = empty
            var instanceUsingAppendContentsOf: FIFOBoundedSet<Int> = empty
            
            // Test
            _ = instanceUsingAppendContentsOf.append(contentsOf: elements)
            for element in elements {
                _ = instanceUsingAppend.append(element)
            }
            
            // Verify
            return instanceUsingAppendContentsOf == instanceUsingAppend
        }
    }
    
    func testProp_appendContentOf_appendAndAppendContentsOfProduceIdenticalEffectsGivenUpToMaxSizeIdenticalInput() {
        property(
            "append and appendContentOf produce identical effects given up to maximumCount identical input",
            arguments: checkerArguments
        ) <- forAll(
            [Int].arbitrary.suchThat { !$0.isEmpty }
        ) { (elements: [Int]) in
            
            // Set up
            let empty: FIFOBoundedSet<Int> = try FIFOBoundedSet(maximumCount: elements.count)
            var instanceUsingAppend: FIFOBoundedSet<Int> = empty
            var instanceUsingAppendContentsOf: FIFOBoundedSet<Int> = empty
            
            // Test
            let actualEffectsAppendContentsOf: [FIFOBoundedSet.Effect] = instanceUsingAppendContentsOf
                .append(contentsOf: elements)
            let actualEffectsAppend: [FIFOBoundedSet.Effect] = elements
                .compactMap { instanceUsingAppend.append($0) }
            
            // Verify
            return actualEffectsAppendContentsOf == actualEffectsAppend
        }
    }

    // MARK: Performance
    var emptyIntSet: FIFOBoundedSet<Int> {
        get throws { try FIFOBoundedSet<Int>(maximumCount: 3) }
    }
    var fullIntSet: FIFOBoundedSet<Int> {
        get throws {
            var instance = try emptyIntSet
            _ = instance.append(contentsOf: [1, 2, 3])
            
            return instance
        }
    }
    
    func testPerf_append_newElementToEmptySet() throws {
        var instance: FIFOBoundedSet<Int> = try emptyIntSet
        
        measure(metrics: [XCTClockMetric()]) {
            _ = instance.append(0)
        }
    }
    
    func testPerf_appendContentsOf_newElementsToEmptySet() throws {
        var instance: FIFOBoundedSet<Int> = try emptyIntSet
        
        measure(metrics: [XCTClockMetric()]) {
            _ = instance.append(contentsOf: [0, 1])
        }
    }
    
    func testPerf_append_newElementToFullSet() throws {
        var instance: FIFOBoundedSet<Int> = try fullIntSet
        
        measure(metrics: [XCTClockMetric()]) {
            _ = instance.append(4)
        }
    }
    
    func testPerf_appendContentsOf_newElementsToFullSet() throws {
        var instance: FIFOBoundedSet<Int> = try fullIntSet
        
        measure(metrics: [XCTClockMetric()]) {
            _ = instance.append(contentsOf: [4, 5])
        }
    }
    
    func testPerf_append_existingElementToFullSet() throws {
        var instance: FIFOBoundedSet<Int> = try fullIntSet
        
        measure(metrics: [XCTClockMetric()]) {
            _ = instance.append(1)
        }
    }
    
    func testPerf_appendContentsOf_existingElementsToFullSet() throws {
        var instance: FIFOBoundedSet<Int> = try fullIntSet
        
        measure(metrics: [XCTClockMetric()]) {
            _ = instance.append(contentsOf: [1, 2])
        }
    }
}
