import App
import CollectionsBenchmark

var benchmark = Benchmark(title: "MultiSet")

benchmark.add(
    title: "New Vote",
    input: Int.self
) { size in
    var instance: MultiSet<Int> = MultiSet(minimumCapacity: size)
    
    return { _ in
        for element in 0..<size {
            blackHole(instance.update(byAdding: element))
        }
    }
}

benchmark.add(
    title: "Vote Change",
    input: Int.self
) { size in
    var instance: MultiSet<Int> = MultiSet(minimumCapacity: size)
    for element in 0..<size {
        instance.update(byAdding: element)
    }
    
    return { timer in
        for element in 0..<size {
            blackHole(instance.update(byAdding: element, andRemoving: size - element))
        }
    }
}

benchmark.main()
