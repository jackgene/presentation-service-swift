/// Mutable MultiSet. Not thread-safe.
public struct MultiSet<Element> where Element: Hashable {
    var countsByElement: [Element: UInt]
    var elementsByCount: [UInt: [Element]]
    
    public init(expectedElements: Int) {
        self.countsByElement = Dictionary(minimumCapacity: expectedElements)
        self.elementsByCount = Dictionary(minimumCapacity: expectedElements)
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
        
        if let oldCountItems: [Element] = elementsByCount[oldCount] {
            if oldCountItems.count == 1 && oldCountItems[0] == element {
                elementsByCount[oldCount] = nil
            } else {
                elementsByCount[oldCount] = oldCountItems.filter { $0 != element }
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
            
            var newCountItems: [Element] = elementsByCount[newCount] ?? []
            newCountItems.insert(element, at: 0)
            elementsByCount[newCount] = newCountItems
        }
        
        if let oldCountItems: [Element] = elementsByCount[oldCount] {
            if oldCountItems.count == 1 && oldCountItems[0] == element {
                elementsByCount[oldCount] = nil
            } else {
                elementsByCount[oldCount] = oldCountItems.filter { $0 != element }
            }
        }
    }
    
    public mutating func update(byAdding addition: Element, andRemoving removal: Element? = nil) {
        add(element: addition)
        if let removal = removal {
            remove(element: removal)
        }
    }
}
