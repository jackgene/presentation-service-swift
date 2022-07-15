// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "PresentationService",
  platforms: [.macOS(.v11)],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    .package(url: "https://github.com/httpswift/swifter.git", .upToNextMajor(from: "1.5.0")),
  ],
  targets: [
    .target(
      name: "PresentationServiceFramework",
      dependencies: [
        .product(name: "Logging", package: "swift-log")
      ]
    ),
    .executableTarget(
      name: "PresentationService",
      dependencies: [
        "PresentationServiceFramework",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Swifter", package: "swifter")
      ]
    ),
  ]
)
