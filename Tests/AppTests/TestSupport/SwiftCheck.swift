import Foundation
@preconcurrency import SwiftCheck

let checkerArguments: CheckerArguments = CheckerArguments(
    maxAllowableSuccessfulTests: getenv("SWIFTCHECK_MIN_SUCCESSFUL_TEST")
        .flatMap { Int(String(cString: $0)) } ?? 100
)
