// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pdviewer-settings",
    platforms: [
            .iOS(.v13)
        ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "pdviewer-settings",
            targets: ["pdviewer-settings"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .upToNextMajor(from: "5.0.2")),
        .package(url: "https://github.com/devicekit/DeviceKit.git", .upToNextMajor(from: "5.6.0")),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack.git", .upToNextMajor(from: "3.8.5")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "pdviewer-settings",
            dependencies: [
              "SwiftyJSON",
              "DeviceKit",
              .product(name: "CocoaLumberjack", package: "CocoaLumberjack"),
              .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack")
          ],
            resources: [
                .process("Resources")  // 或 .copy("Resources")
            ]),
    ]
)
