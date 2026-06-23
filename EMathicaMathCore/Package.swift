// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EMathicaMathCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "EMathicaMathCore",
            targets: ["EMathicaMathCore"]
        )
    ],
    targets: [
        .target(
            name: "EMathicaMathCore",
            path: "Sources/EMathicaMathCore"
        ),
        .testTarget(
            name: "EMathicaMathCoreTests",
            dependencies: ["EMathicaMathCore"],
            path: "Tests/EMathicaMathCoreTests"
        )
    ]
)
