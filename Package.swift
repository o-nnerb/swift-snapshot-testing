// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-snapshot-testing",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "XCSnapshot",
            targets: ["XCSnapshot"]
        ),
        .library(
            name: "SnapshotTesting",
            targets: ["SnapshotTesting"]
        ),
    ],
    targets: [
        .target(
            name: "XCSnapshot"
        ),
        .target(
            name: "SnapshotTesting",
            dependencies: ["XCSnapshot"]
        ),
        .testTarget(
            name: "XCSnapshotTests",
            dependencies: ["XCSnapshot"],
            exclude: ["__Snapshots__"]
        ),
        .testTarget(
            name: "SnapshotTestingTests",
            dependencies: ["SnapshotTesting"],
            exclude: ["__Snapshots__"]
        ),
    ]
)
