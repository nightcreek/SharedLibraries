// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "EMathicaMathInputKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "EMathicaMathInputCore",
            targets: ["EMathicaMathInputCore"]
        ),
        .library(
            name: "EMathicaMathInputUI",
            targets: ["EMathicaMathInputUI"]
        ),
        .library(
            name: "EMathicaMathInputKit",
            targets: ["EMathicaMathInputCore", "EMathicaMathInputUI"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "EMathicaMathInputCore",
            dependencies: []
        ),
        .target(
            name: "EMathicaMathInputUI",
            dependencies: ["EMathicaMathInputCore"]
        ),
        .testTarget(
            name: "EMathicaMathInputCoreTests",
            dependencies: ["EMathicaMathInputCore"]
        )
    ]
)
