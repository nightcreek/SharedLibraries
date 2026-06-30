// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EMathicaHomeFeature",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "EMathicaHomeFeature",
            targets: ["EMathicaHomeFeature"]
        )
    ],
    dependencies: [
        .package(path: "../EMathicaDocumentKit"),
        .package(path: "../EMathicaThemeKit"),
        .package(path: "../EMathicaWorkspaceKit")
    ],
    targets: [
        .target(
            name: "EMathicaHomeFeature",
            dependencies: [
                "EMathicaDocumentKit",
                "EMathicaThemeKit",
                "EMathicaWorkspaceKit"
            ],
            path: "Sources/EMathicaHomeFeature"
        ),
        .testTarget(
            name: "EMathicaHomeFeatureTests",
            dependencies: ["EMathicaHomeFeature"],
            path: "Tests/EMathicaHomeFeatureTests"
        )
    ]
)
