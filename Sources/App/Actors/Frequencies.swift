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

    private func update(item: String, delta: Int,
                        countsByItem: inout [String: Int],
                        itemsByCount: inout [Int: [String]]) {
        guard delta != 0 else {
            return
        }

        let oldCount: Int = countsByItem[item] ?? 0
        let newCount: Int = oldCount + delta

        countsByItem.updateValue(newCount, forKey: item)

        var newCountItems: [String] = itemsByCount[newCount] ?? []
        if delta > 0 {
            newCountItems.append(item)
        } else {
            newCountItems.insert(item, at: 0)
        }

        itemsByCount.updateValue(
            (itemsByCount[oldCount] ?? []).filter { $0 != item },
            forKey: oldCount
        )
        itemsByCount.updateValue(
            newCountItems,
            forKey: newCount
        )
    }

    func updated(byAdding addition: String,
                 andRemoving removal: String? = nil) -> Frequencies {
        var countsByItem = self.countsByItem
        var itemsByCount = self.itemsByCount
        update(
            item: addition, delta: 1,
            countsByItem: &countsByItem,
            itemsByCount: &itemsByCount
        )
        if let removal = removal {
            update(
                item: removal, delta: -1,
                countsByItem: &countsByItem,
                itemsByCount: &itemsByCount
            )
        }

        return Frequencies(
            countsByItem: countsByItem,
            itemsByCount: itemsByCount.filter { count, items in
                count > 0 && !items.isEmpty
            }
        )
    }
}
