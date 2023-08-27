import SwiftCheck

extension Gen where A == Character {
    static let alphabeticalLowercase: Gen<A> = Gen<A>.fromElements(in: "a"..."z")
}

extension Gen where A == String {
    static let alphabeticalLowercase: Gen<A> = Gen<Character>
        .alphabeticalLowercase
        .proliferate
        .map { String($0) }
}

extension Gen where A: Arbitrary & SignedInteger {
    static var positive: Gen<A> { Positive.arbitrary.map { $0.getPositive } }
}
