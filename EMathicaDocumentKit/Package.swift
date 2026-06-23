// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EMathicaDocumentKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "EMathicaDocumentKit",
            targets: ["EMathicaDocumentKit"]
        )
    ],
    dependencies: [
        .package(path: "../EMathicaMathCore")
    ],
    targets: [
        .target(
            name: "EMathicaDocumentKit",
            dependencies: ["EMathicaMathCore"],
            path: "Sources/EMathicaDocumentKit"
        ),
        .testTarget(
            name: "EMathicaDocumentKitTests",
            dependencies: ["EMathicaDocumentKit"],
            path: "Tests/EMathicaDocumentKitTests"
        )
    ]
)
