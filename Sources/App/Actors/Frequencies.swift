struct Frequencies {
    let countsByItem: [String: Int]
    let itemsByCount: [Int: [String]]

    init(expectedItems: Int) {
        self.countsByItem = [String: Int](minimumCapacity: expectedItems)
        self.itemsByCount = [Int: [String]](minimumCapacity: expectedItems)
    }

    init(countsByItem: [String: Int], itemsByCount: [Int: [String]]) {
        self.countsByItem = countsByItem
        self.itemsByCount = itemsByCount
    }

    func updated(item: String, delta: Int) -> Frequencies {
        if delta == 0 {
            return self
        } else {
            let oldCount: Int = countsByItem[item] ?? 0
            let newCount: Int = oldCount + delta

            var countsByItem = self.countsByItem
            countsByItem.updateValue(newCount, forKey: item)

            var newCountItems: [String] = itemsByCount[newCount] ?? []
            if delta > 0 {
                newCountItems.append(item)
            } else {
                newCountItems.insert(item, at: 0)
            }

            var itemsByCount = self.itemsByCount
            itemsByCount.updateValue(
                (itemsByCount[oldCount] ?? []).filter { $0 != item },
                forKey: oldCount
            )
            itemsByCount.updateValue(
                newCountItems,
                forKey: newCount
            )

            return Frequencies(
                countsByItem: countsByItem,
                itemsByCount: itemsByCount.filter { count, items in
                    count > 0 && !items.isEmpty
                }
            )
        }
    }
}
