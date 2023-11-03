// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "PresentationService",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", exact: "4.83.1"),
        .package(url: "https://github.com/apple/swift-collections.git", exact: "1.0.4"),
        // Tests
        .package(url: "https://github.com/nschum/SwiftHamcrest.git", exact: "2.2.2"),
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
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds.
                // See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
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
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "SwiftCheck", package: "SwiftCheck"),
                .product(name: "SwiftHamcrest", package: "SwiftHamcrest"),
                .product(name: "XCTVapor", package: "vapor"),
            ]
        )
    ]
)
