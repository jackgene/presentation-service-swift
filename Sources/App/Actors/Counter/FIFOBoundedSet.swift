import DequeModule

/// FIFO Bounded Set
public struct FIFOBoundedSet<Element>: Equatable where Element : Hashable {
    public enum Effect: Equatable {
        case added
        case addedEvicting(value: Element)
        case notAdded
    }
    
    public let maximumCapacity: Int
    var uniques: Set<Element>
    var insertionOrder: Deque<Element>
    
    public init?(maximumCapacity: Int) {
        guard maximumCapacity > 0 else { return nil }
        
        self.maximumCapacity = maximumCapacity
        self.uniques = Set(minimumCapacity: maximumCapacity)
        self.insertionOrder = Deque(minimumCapacity: maximumCapacity)
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
            
            if uniques.count <= maximumCapacity {
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
