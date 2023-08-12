@testable import App
import SwiftCheck
import SwiftHamcrest
import XCTest

final class FIFOBoundedSetTests: XCTestCase {
    var emptyStringSet: FIFOBoundedSet<String> {
        get throws {
            guard let instance = FIFOBoundedSet<String>(maximumCapacity: 2) else {
                XCTFail("unable to instantiate FIFOBoundedSet")
                throw XCTSkip()
            }
            return instance
        }
    }
    var emptyIntSet: FIFOBoundedSet<Int> {
        get throws {
            guard let instance = FIFOBoundedSet<Int>(maximumCapacity: 2) else {
                XCTFail("unable to instantiate FIFOBoundedSet")
                throw XCTSkip()
            }
            return instance
        }
    }
    var fullIntSet: FIFOBoundedSet<Int> {
        get throws {
            var instance = try emptyIntSet
            _ = instance.append(contentsOf: [1, 2, 3])
            
            return instance
        }
    }

    // MARK: Specifications
    func testSpec_init_empty() {
        // Set up & Test
        let instance: FIFOBoundedSet<String>? = FIFOBoundedSet(maximumCapacity: 2)
        
        // Verify
        assertThat(instance, not(nilValue()))
        assertThat(instance!, hasCount(0))
    }
    
    func testSpec_init_zeroMaximumCapacity() {
        // Set up & Test
        let instance: FIFOBoundedSet<String>? = FIFOBoundedSet(maximumCapacity: 0)
        
        // Verify
        assertThat(instance, nilValue())
    }
    
    func testSpec_append_newElementToEmptyInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        
        // Test
        let actualEffect: FIFOBoundedSet<String>.Effect = instance.append("test")
        
        // Verify
        assertThat(actualEffect, equalTo(.added))
        assertThat(instance.insertionOrder, equalTo(["test"]))
    }
    
    func testSpec_append_newElementToPartiallyFilledInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        _ = instance.append(contentsOf: ["test-1"])
        
        // Test
        let actualEffect: FIFOBoundedSet<String>.Effect = instance.append("test-2")
        
        // Verify
        assertThat(actualEffect, equalTo(.added))
        assertThat(instance.insertionOrder, equalTo(["test-1", "test-2"]))
    }
    
    func testSpec_append_existingElementToPartiallyFilledInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        _ = instance.append(contentsOf: ["test"])
        
        // Test
        let actualEffect: FIFOBoundedSet<String>.Effect = instance.append("test")
        
        // Verify
        assertThat(actualEffect, equalTo(.notAdded))
        assertThat(instance.insertionOrder, equalTo(["test"]))
    }
    
    func testSpec_append_newElementToFullInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        _ = instance.append(contentsOf: ["test-1", "test-2"])
        
        // Test
        let actualEffect: FIFOBoundedSet<String>.Effect = instance.append("test-3")
        
        // Verify
        assertThat(actualEffect, equalTo(.addedEvicting(value: "test-1")))
        assertThat(instance.insertionOrder, equalTo(["test-2", "test-3"]))
    }
    
    func testSpec_append_existingElementToFullInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        _ = instance.append(contentsOf: ["test-1", "test-2"])
        
        // Test
        let actualEffect: FIFOBoundedSet<String>.Effect = instance.append("test-1")
        
        // Verify
        assertThat(actualEffect, equalTo(.notAdded))
        assertThat(instance.insertionOrder, equalTo(["test-2", "test-1"]))
    }
    
    func testSpec_appendContentOf_newElementsToEmptyInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        
        // Test
        let actualEffects: [FIFOBoundedSet<String>.Effect] = instance.append(contentsOf: ["test-1", "test-2"])
        
        // Verify
        assertThat(actualEffects, equalTo([.added, .added]))
        assertThat(instance.insertionOrder, equalTo(["test-1", "test-2"]))
    }
    
    func testSpec_appendContentOf_sameElementsToEmptyInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        
        // Test
        let actualEffects: [FIFOBoundedSet<String>.Effect] = instance.append(contentsOf: ["test", "test"])
        
        // Verify
        assertThat(actualEffects, equalTo([.added, .notAdded]))
        assertThat(instance.insertionOrder, equalTo(["test"]))
    }
    
    func testSpec_appendContentOf_newElementsToPartiallyFilledInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        _ = instance.append(contentsOf: ["test-1"])
        
        // Test
        let actualEffects: [FIFOBoundedSet<String>.Effect] = instance.append(contentsOf: ["test-2", "test-3"])
        
        // Verify
        assertThat(actualEffects, equalTo([.added, .addedEvicting(value: "test-1")]))
        assertThat(instance.insertionOrder, equalTo(["test-2", "test-3"]))
    }
    
    func testSpec_appendContentOf_existingAndNewElementsToFullInstance() throws {
        // Set up
        var instance: FIFOBoundedSet<String> = try emptyStringSet
        _ = instance.append(contentsOf: ["test-1", "test-2"])
        
        // Test
        let actualEffects: [FIFOBoundedSet<String>.Effect] = instance.append(contentsOf: ["test-1", "test-3"])
        
        // Verify
        assertThat(actualEffects, equalTo([.notAdded, .addedEvicting(value: "test-2")]))
        assertThat(instance.insertionOrder, equalTo(["test-1", "test-3"]))
    }
    
    // MARK: Properties
    func testProp_appendContentOf_neverContainMoreElementsThanMaxSize() {
        property("never contain more elements than maxSize") <- forAll {
            (maxSizeGen: Positive<Int>, elements: [Int]) in
            
            // Set up
            let maxSize: Int = maxSizeGen.getPositive
            guard
                var instance: FIFOBoundedSet<Int> = FIFOBoundedSet(maximumCapacity: maxSize)
            else {
                XCTFail("unable to instantiate FIFOBoundedSet")
                throw XCTSkip()
            }
            
            // Test
            _ = instance.append(contentsOf: elements)
            
            // Verify
            return instance.count <= maxSize
        }
    }
    
    func testProp_appendContentOf_alwaysIncludeTheMostRecentlyAddedElements() {
        property("always include the most recently added elements") <- forAll {
            (maxSizeGen: Positive<Int>, elements: [Int]) in
            
            // Set up
            let maxSize: Int = maxSizeGen.getPositive
            guard
                var instance: FIFOBoundedSet<Int> = FIFOBoundedSet(maximumCapacity: maxSize)
            else {
                XCTFail("unable to instantiate FIFOBoundedSet")
                throw XCTSkip()
            }
            
            // Test
            _ = instance.append(contentsOf: elements)
            
            // Verify
            return Set(elements.suffix(maxSize)).isSubset(of: instance)
        }
    }
    
    func testProp_appendContentOf_onlyEvictTheLeastRecentlyAddedElements() {
        property("only evict the least recently added elements") <- forAll {
            (maxSizeGen: Positive<Int>, elements: [Int]) in
            
            // Set up
            let maxSize: Int = maxSizeGen.getPositive
            guard
                var instance: FIFOBoundedSet<Int> = FIFOBoundedSet(maximumCapacity: maxSize)
            else { throw XCTSkip("unable to instantiate FIFOBoundedSet") }
            
            // Test
            let actualEvictions: [Int] = instance.append(contentsOf: elements)
                .compactMap {
                    switch $0 {
                    case let .addedEvicting(value): return value
                    case .added: return nil
                    case .notAdded: return nil
                    }
                }
            
            // Verify
            return Set(actualEvictions).isSubset(of: elements.dropLast(maxSize))
        }
    }
    
    func testProp_appendContentOf_neverEvictWhenNotFull() {
        property("never evict when not full") <- forAll {
            (elements: [Int]) in
            
            // Set up
            guard
                var instance: FIFOBoundedSet<Int> = FIFOBoundedSet(maximumCapacity: max(elements.count, 1))
            else { throw XCTSkip("unable to instantiate FIFOBoundedSet") }
            
            // Test
            let actualEvictions: [Int] = instance.append(contentsOf: elements)
                .compactMap {
                    switch $0 {
                    case let .addedEvicting(value): return value
                    case .added: return nil
                    case .notAdded: return nil
                    }
                }
            
            // Verify
            return actualEvictions.isEmpty ^&&^ Set(instance) == Set(elements)
        }
    }
    
    func testProp_appendContentOf_appendAndAppendContentsOfAreEquivalentGivenIdenticalInput() {
        property("add and addAll are equivalent given identical input") <- forAll {
            (maxSizeGen: Positive<Int>, elements: [Int]) in
            
            // Set up
            guard
                let empty: FIFOBoundedSet<Int> = FIFOBoundedSet(maximumCapacity: max(elements.count, 1))
            else { throw XCTSkip("unable to instantiate FIFOBoundedSet") }
            var instanceUsingAppend: FIFOBoundedSet<Int> = empty
            var instanceUsingAppendContentsOf: FIFOBoundedSet<Int> = empty
            
            // Test
            for element in elements {
                _ = instanceUsingAppend.append(element)
            }
            _ = instanceUsingAppendContentsOf.append(contentsOf: elements)
            
            // Verify
            return instanceUsingAppendContentsOf == instanceUsingAppend
        }
    }
    
    // MARK: Performance
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
