// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppUpdately",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "AppUpdately", targets: ["AppUpdately"]),
    ],
    dependencies: [
        .package(url: "https://github.com/WeTransfer/Mocker.git", .upToNextMajor(from: "2.3.0"))
    ],
    targets: [
        .target(
            name: "AppUpdately",
            dependencies: []),
        .testTarget(
            name: "AppUpdatelyTests",
            dependencies: ["AppUpdately", "Mocker"]),
    ]
)
