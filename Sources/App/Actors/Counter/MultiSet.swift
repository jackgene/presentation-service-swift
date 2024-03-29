/// Mutable MultiSet. Not thread-safe.
public struct MultiSet<Element> where Element: Hashable {
    var countsByElement: [Element: UInt]
    public internal(set) var elementsByCount: [UInt: [Element]]
    
    public init(minimumCapacity: Int) {
        self.countsByElement = Dictionary(minimumCapacity: minimumCapacity)
        self.elementsByCount = Dictionary(minimumCapacity: minimumCapacity)
    }
    
    private mutating func add(element: Element) {
        let oldCount: UInt = countsByElement[element] ?? 0
        guard oldCount != UInt.max else {
            return
        }
        
        let newCount: UInt = oldCount + 1
        
        // Update countsByElement
        countsByElement[element] = newCount
        
        // Update elementsByCount
        var newCountElems: [Element] = elementsByCount[newCount] ?? []
        newCountElems.append(element)
        elementsByCount[newCount] = newCountElems
        
        if let oldCountElems: [Element] = elementsByCount[oldCount] {
            if oldCountElems.count == 1 && oldCountElems[0] == element {
                elementsByCount[oldCount] = nil
            } else {
                elementsByCount[oldCount] = oldCountElems
                    .filter { $0 != element }
            }
        }
    }
    
    private mutating func remove(element: Element) {
        guard let oldCount: UInt = countsByElement[element] else {
            return
        }
        
        let newCount: UInt = oldCount - 1
        
        if newCount == 0 {
            countsByElement[element] = nil
        } else {
            countsByElement[element] = newCount
            
            var newCountElems: [Element] = elementsByCount[newCount] ?? []
            newCountElems.insert(element, at: 0)
            elementsByCount[newCount] = newCountElems
        }
        
        if let oldCountElems: [Element] = elementsByCount[oldCount] {
            if oldCountElems.count == 1 && oldCountElems[0] == element {
                elementsByCount[oldCount] = nil
            } else {
                elementsByCount[oldCount] = oldCountElems
                    .filter { $0 != element }
            }
        }
    }
    
    public mutating func update(
        byAdding addition: Element, andRemoving removal: Element? = nil
    ) {
        add(element: addition)
        if let removal = removal {
            remove(element: removal)
        }
    }
    
    public var description: String { "MultiSet(\(countsByElement))" }
}
