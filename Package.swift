// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChatLibrary",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "LocalData",
            targets: ["LocalData"]),
        .library(
            name: "FeatureChat",
            targets: ["FeatureChat"])
    ],
    targets: [
        .target(name: "LocalData"),
        .target(
            name: "FeatureChat",
            dependencies: ["LocalData"]
        )
    ]
)
