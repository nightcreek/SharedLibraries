// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EMathicaWorkspaceKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "EMathicaWorkspaceKit",
            targets: ["EMathicaWorkspaceKit"]
        )
    ],
    dependencies: [
        .package(path: "../EMathicaMathCore"),
        .package(path: "../EMathicaDocumentKit"),
        .package(path: "../EMathicaThemeKit"),
        .package(path: "../EMathicaMathInputKit")
    ],
    targets: [
        .target(
            name: "EMathicaWorkspaceKit",
            dependencies: [
                "EMathicaMathCore",
                "EMathicaDocumentKit",
                "EMathicaThemeKit",
                "EMathicaMathInputKit"
            ],
            path: "Sources/EMathicaWorkspaceKit"
        ),
        .testTarget(
            name: "EMathicaWorkspaceKitTests",
            dependencies: ["EMathicaWorkspaceKit"],
            path: "Tests/EMathicaWorkspaceKitTests"
        )
    ]
)
