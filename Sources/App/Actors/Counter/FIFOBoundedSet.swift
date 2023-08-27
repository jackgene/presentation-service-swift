import DequeModule

/// First-In, First-Out bounded set.
/// This is basically an LRU-cache that returns evictions as elements are added.
public struct FIFOBoundedSet<Element>: Equatable where Element : Hashable {
    public enum Effect: Equatable {
        case added
        case addedEvicting(value: Element)
        case notAdded
    }
    
    public let maximumCount: Int
    var uniques: Set<Element>
    var insertionOrder: Deque<Element>
    
    public init(maximumCount: Int) throws {
        guard maximumCount > 0 else {
            throw Error.illegalArgument(reason: "maximumCount must be at least 1")
        }
        
        self.maximumCount = maximumCount
        self.uniques = Set(minimumCapacity: maximumCount)
        self.insertionOrder = Deque(minimumCapacity: maximumCount)
    }
    
    public mutating func append(_ element: Element) -> Effect {
        if uniques.contains(element) {
            if insertionOrder.last != element {
                // Move to end
                insertionOrder.removeAll(where: { $0 == element })
                insertionOrder.append(element)
            }
            
            return .notAdded
        } else {
            uniques.insert(element)
            insertionOrder.append(element)
            
            if uniques.count <= maximumCount {
                return .added
            } else {
                guard
                    let oldestElement: Element = insertionOrder.popFirst()
                else {
                    // This really should not ever happen
                    return .added
                }
                uniques.remove(oldestElement)
                return .addedEvicting(value: oldestElement)
            }
        }
    }
    
    public mutating func append<S>(
        contentsOf newElements: S
    ) -> [Effect] where Element == S.Element, S : Sequence {
        newElements.map { append($0) }
    }
}

extension FIFOBoundedSet: Sequence {
    public func makeIterator() -> Deque<Element>.Iterator {
        insertionOrder.makeIterator()
    }
}

extension FIFOBoundedSet: Collection {
    public typealias Index = Int
    
    public var startIndex: Int { insertionOrder.startIndex }
    public var endIndex: Int { insertionOrder.endIndex }
    
    public subscript(position: Int) -> Element {
        insertionOrder[position]
    }
    
    public func index(after i: Int) -> Int {
        insertionOrder.index(after: i)
    }
}

extension FIFOBoundedSet: Encodable where Element : Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(insertionOrder)
    }
}
