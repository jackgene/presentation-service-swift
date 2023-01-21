struct MultiSet<Element> where Element: Hashable {
    static func update(item: Element, delta: Int,
                       countsByItem: inout [Element: UInt],
                       itemsByCount: inout [UInt: [Element]]) {
        guard delta != 0 else {
            return
        }
        
        let oldCount: UInt = countsByItem[item] ?? 0
        let newCount: UInt
        if delta > 0 {
            let (partial, overflow) = oldCount.addingReportingOverflow(UInt(delta))
            
            newCount = overflow ? UInt.max : partial
        } else {
            let (partial, overflow) = oldCount.subtractingReportingOverflow(UInt(-delta))
            
            newCount = overflow ? UInt.min : partial
        }
        
        if newCount == 0 {
            countsByItem[item] = nil
        } else {
            countsByItem[item] = newCount
            
            var newCountItems: [Element] = itemsByCount[newCount] ?? []
            if delta > 0 { newCountItems.append(item) }
            else { newCountItems.insert(item, at: 0) }
            itemsByCount.updateValue(
                newCountItems,
                forKey: newCount
            )
        }
        
        // Remove itemsByCount for old count
        let oldCountItems: [Element] = (itemsByCount[oldCount] ?? []).filter { $0 != item }
        itemsByCount[oldCount] = oldCountItems.isEmpty ? nil : oldCountItems
    }
    
    // internal instead of private for testability
    static func increment(element: Element,
                          countsByElement: inout [Element: UInt],
                          elementsByCount: inout [UInt: [Element]]) {
        update(item: element, delta: 1, countsByItem: &countsByElement, itemsByCount: &elementsByCount)
    }
    
    // internal instead of private for testability
    static func decrement(element: Element,
                          countsByElement: inout [Element: UInt],
                          elementsByCount: inout [UInt: [Element]]) {
        update(item: element, delta: -1, countsByItem: &countsByElement, itemsByCount: &elementsByCount)
    }
    
    let countsByElement: [Element: UInt]
    let elementsByCount: [UInt: [Element]]
    
    public init(expectedElements: Int) {
        self.countsByElement = [Element: UInt](minimumCapacity: expectedElements)
        self.elementsByCount = [UInt: [Element]](minimumCapacity: expectedElements)
    }
    
    // internal instead of private for testability
    init(countsByElement: [Element: UInt], elementsByCount: [UInt: [Element]]) {
        self.countsByElement = countsByElement
        self.elementsByCount = elementsByCount
    }
    
    public func updated(byAdding addition: Element,
                        andRemoving removal: Element? = nil) -> MultiSet {
        var countsByElement = self.countsByElement
        var elementsByCount = self.elementsByCount
        Self.increment(
            element: addition,
            countsByElement: &countsByElement,
            elementsByCount: &elementsByCount
        )
        if let removal = removal {
            Self.decrement(
                element: removal,
                countsByElement: &countsByElement,
                elementsByCount: &elementsByCount
            )
        }
        
        return MultiSet(
            countsByElement: countsByElement,
            elementsByCount: elementsByCount
        )
    }
}
