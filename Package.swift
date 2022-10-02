// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Freedux",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6),],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Freedux",
            targets: ["Freedux"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AnarchoSystems/SwiftDI.git", branch: "main"),
        .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "0.8.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Freedux",
            dependencies: ["SwiftDI",
                           .product(name: "CasePaths", package: "swift-case-paths")]),
        .testTarget(
            name: "FreeduxTests",
            dependencies: ["Freedux"]),
    ]
)
