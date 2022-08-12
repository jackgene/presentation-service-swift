import Foundation

struct Metrics {
    private let lock: NSLock = NSLock()
    private var valuesByTime: [(Int,Int)] = []
    private(set) var value: Int = 0

    mutating func record(newValue: Int) {
        lock.lock()
        defer { lock.unlock() }

        let micros: Int = Int(truncatingIfNeeded: Int64((Date().timeIntervalSince1970 * 1_000_000.0).rounded()))
        let index: Int = Int(micros % 10)
        let (lastMicros, lastValue) = valuesByTime[index]
        if lastMicros == micros {
            value += newValue
            valuesByTime[index] = (micros, lastValue + newValue)
        } else {
            if lastMicros != micros - 10 {
                print("Warning skipped!!")
            }
            value = newValue - lastValue
            valuesByTime[index] = (micros, newValue)
        }
    }
}
