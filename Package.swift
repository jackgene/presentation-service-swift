// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "PresentationService",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", exact: "4.113.2"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
//        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/apple/swift-collections.git", exact: "1.1.1"),
        // Tests
        .package(url: "https://github.com/nschum/SwiftHamcrest.git", exact: "2.2.4"),
        .package(url: "https://github.com/typelift/SwiftCheck.git", exact: "0.12.0"),
        // Benchmark
        .package(url: "https://github.com/apple/swift-collections-benchmark", exact: "0.0.3"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "DequeModule", package: "swift-collections"),
            ],
            exclude: ["Models/Configuration.plist"],
            swiftSettings: swiftSettings + [
                // Enable regex literal
                .unsafeFlags(["-enable-bare-slash-regex"]),
            ]
        ),
        .executableTarget(
            name: "presentation-service",
            dependencies: [.target(name: "App")],
            path: "Sources/Run"),
        .executableTarget(
            name: "Benchmark",
            dependencies: [
                .target(name: "App"),
                .product(name: "CollectionsBenchmark", package: "swift-collections-benchmark"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "SwiftCheck", package: "SwiftCheck"),
                .product(name: "SwiftHamcrest", package: "SwiftHamcrest"),
                .product(name: "XCTVapor", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ],
    swiftLanguageModes: [.v5]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableExperimentalFeature("StrictConcurrency"),
] }
