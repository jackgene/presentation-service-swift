import DequeModule

/// First-In, First-Out bounded set.
/// This is basically an LRU-cache that returns evictions as elements are added.
public struct FIFOBoundedSet<Element>: Equatable where Element : Hashable {
    public enum Effect: Equatable {
        case appended(element: Element)
        case appendedEvicting(element: Element, evicting: Element)
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
    
    public mutating func append(_ element: Element) -> Effect? {
        if uniques.contains(element) {
            if insertionOrder.last != element {
                // Move to end
                insertionOrder.removeAll(where: { $0 == element })
                insertionOrder.append(element)
            }
            
            return nil
        } else {
            uniques.insert(element)
            insertionOrder.append(element)
            
            if uniques.count <= maximumCount {
                return .appended(element: element)
            } else {
                guard
                    let oldestElement: Element = insertionOrder.popFirst()
                else {
                    // This really should not ever happen
                    return .appended(element: element)
                }
                uniques.remove(oldestElement)
                return .appendedEvicting(element: element, evicting: oldestElement)
            }
        }
    }
    
    public mutating func append<S>(
        contentsOf newElements: S
    ) -> [Effect] where Element == S.Element, S : Sequence {
        let uniques = self.uniques
        
        return newElements
            .compactMap {
                switch append($0) {
                case .appendedEvicting(let element, let evicted) where !uniques.contains(evicted):
                    // Evicted value was part of newElements, and effectively never added, and hence not evicted
                    return .appended(element: element)
                case let other: return other
                }
            }
            .suffix(maximumCount)
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
