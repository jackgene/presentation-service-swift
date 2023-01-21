@testable import App
import SwiftCheck
import SwiftHamcrest
import XCTest

final class MultiSetTests: XCTestCase {
    let empty: MultiSet<String> = MultiSet(expectedElements: 2)
    
    // MARK: Specifications
    func testInit_empty() {
        // Set up & Test
        let instance: MultiSet<String> = empty
        
        // Verify
        assertThat(instance.countsByElement, hasCount(0))
        assertThat(instance.elementsByCount, hasCount(0))
    }
    
    func testUpdated_recordCorrectCounts() {
        // Set up
        let instanceSetup: MultiSet<String> = empty
        
        // Test
        let instance: MultiSet<String> = instanceSetup
            .updated(byAdding: "test-2", andRemoving: "test-1") // test-1: 0, test-2: 1
            .updated(byAdding: "test-1")                        // test-1: 1, test-2: 1
            .updated(byAdding: "test-2", andRemoving: "test-1") // test-1: 0, test-2: 2
            .updated(byAdding: "test-1")                        // test-1: 1, test-2: 2
            .updated(byAdding: "test-1")                        // test-1: 2, test-2: 2
            .updated(byAdding: "test-2", andRemoving: "test-1") // test-1: 1, test-2: 3
            .updated(byAdding: "test-1")                        // test-1: 2, test-2: 3
            .updated(byAdding: "test-2", andRemoving: "test-1") // test-1: 1, test-2: 4
            .updated(byAdding: "test-1")                        // test-1: 2, test-2: 4
            .updated(byAdding: "test-2", andRemoving: "test-1") // test-1: 1, test-2: 5
        
        // Verify
        assertThat(instance.countsByElement, equalTo(["test-1": 1, "test-2": 5]))
        assertThat(instance.elementsByCount, equalTo([1: ["test-1"], 5: ["test-2"]]))
    }
    
    func testUpdated_decrementZero() {
        // Set up
        let instanceSetup: MultiSet<String> = empty
        
        // Test
        let instance = instanceSetup.updated(
            byAdding: "unused", andRemoving: "test"
        )
        
        // Verify
        assertThat(instance.countsByElement["test"], nilValue())
    }
    
    func testUpdated_incrementMax() {
        // Set up
        let instanceSetup: MultiSet<String> = MultiSet(
            countsByElement: ["test": UInt.max],
            elementsByCount: [UInt.max: ["test"]]
        )
        
        // Test
        let instance = instanceSetup.updated(byAdding: "test")
        
        // Verify
        assertThat(instance.countsByElement["test"], equalTo(UInt.max))
    }
    
    func testUpdated_appendToItemsByCountWhenIncremented() {
        // Set up
        let instanceSetup: MultiSet<String> = empty
            .updated(byAdding: "test-1")
        
        // Test
        let instance: MultiSet<String> = instanceSetup
            .updated(byAdding: "test-2")
        
        // Verify
        // Incremented value should be appended
        assertThat(instance.elementsByCount, equalTo([1: ["test-1", "test-2"]]))
    }
    
    func testUpdated_prependToItemsByCountWhenDecremented() {
        // Set up
        let instanceSetup: MultiSet<String> = empty
            .updated(byAdding: "test-2")
            .updated(byAdding: "test-2")
        
        // Test
        let instance: MultiSet<String> = instanceSetup
            .updated(byAdding: "test-1", andRemoving: "test-2")
        
        // Verify
        // Decremented value should be prepended
        assertThat(instance.elementsByCount, equalTo([1: ["test-2", "test-1"]]))
    }
    
    func testUpdated_omitZeroCounts() {
        // Set up
        let instanceSetup: MultiSet<String> = empty
        
        // Test
        let instance: MultiSet<String> = instanceSetup
            .updated(byAdding: "test", andRemoving: "test")
        
        // Verify
        assertThat(instance.countsByElement, hasCount(0))
        assertThat(instance.elementsByCount, hasCount(0))
    }
    
    // MARK: Properties
    func testUpdated_countsByItemAndItemsByCountMustReciprocate() {
        property("counts by items and items by counts must reciprocate") <- forAll {
            (increments: [String], decrements: [String]) in
            
            // Test
            var instance: MultiSet<String> = self.empty
            for increment in increments {
                instance = instance.updated(byAdding: increment)
            }
            for decrement in decrements {
                instance = instance.updated(byAdding: "placeholder", andRemoving: decrement)
            }
            
            // Verify
            return (
                (instance.countsByElement.count == instance.elementsByCount.values.flatMap { $0 }.count)
                ^&&^
                (instance.countsByElement.values.allSatisfy { instance.elementsByCount[$0] != nil })
            )
        }
    }
    
    // MARK: Performance
    func testUpdated_newVotePerformance() {
        var instance: MultiSet<String> = empty
        
        measure(metrics: [XCTClockMetric()]) {
            instance = instance.updated(byAdding: "test")
        }
    }
    
    func testUpdated_voteChangePerformance() {
        var instance: MultiSet<String> = empty
        
        measure(metrics: [XCTClockMetric()]) {
            instance = instance.updated(byAdding: "new", andRemoving: "old")
        }
    }
}
