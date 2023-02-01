// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "PresentationService",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        // Tests
        .package(url: "https://github.com/nschum/SwiftHamcrest.git", from: "2.2.2"),
        .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0"),
        // Benchmark
        .package(url: "https://github.com/apple/swift-collections-benchmark", from: "0.0.3"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds.
                // See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
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
