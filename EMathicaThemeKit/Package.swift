// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EMathicaThemeKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "EMathicaThemeKit",
            targets: ["EMathicaThemeKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "EMathicaThemeKit",
            dependencies: [],
            path: "Sources/EMathicaThemeKit"
        ),
        .testTarget(
            name: "EMathicaThemeKitTests",
            dependencies: ["EMathicaThemeKit"],
            path: "Tests/EMathicaThemeKitTests"
        )
    ]
)
