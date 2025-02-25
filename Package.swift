// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(

    name: "swift-coredb",
    platforms: [.iOS(.v13),.watchOS(.v6),.macOS(.v10_15),.tvOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Coredb",
            targets: ["Coredb"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sutext/swift-promise", from: "2.0.0"),
        .package(url: "https://github.com/sutext/swift-json", from: "2.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Coredb",
            dependencies: [
                .product(name: "Promise", package: "swift-promise"),
                .product(name: "JSON", package: "swift-json")
            ]
        ),
        .testTarget(
            name: "CoredbTests",
            dependencies: ["Coredb"]),
    ]
    
)
