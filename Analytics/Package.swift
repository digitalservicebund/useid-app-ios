// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Analytics",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "Analytics",
            targets: ["Analytics"]),
    ],
    dependencies: [
        .package(url: "https://github.com/digitalservicebund/matomo-sdk-ios", branch: "develop"),
    ],
    targets: [
        .target(
            name: "Analytics",
            dependencies: [.product(name: "MatomoTracker", package: "matomo-sdk-ios")]),
        .testTarget(
            name: "AnalyticsTests",
            dependencies: ["Analytics"]),
    ]
)
