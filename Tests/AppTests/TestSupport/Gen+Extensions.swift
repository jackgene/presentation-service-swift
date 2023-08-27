import SwiftCheck

extension Gen where A: Arbitrary & SignedInteger {
    static var positive: Gen<A> { Positive.arbitrary.map { $0.getPositive } }
}
