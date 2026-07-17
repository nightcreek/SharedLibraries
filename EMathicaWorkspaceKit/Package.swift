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
        .package(path: "../EMathicaMathInputKit"),
        .package(path: "../EMathicaFormulaDisplayKit")
    ],
    targets: [
        .target(
            name: "EMathicaWorkspaceKit",
            dependencies: [
                "EMathicaMathCore",
                "EMathicaDocumentKit",
                "EMathicaThemeKit",
                .product(name: "EMathicaMathInputCore", package: "EMathicaMathInputKit"),
                .product(name: "EMathicaMathInputUI", package: "EMathicaMathInputKit"),
                .product(name: "EMathicaFormulaDisplaySwiftUI", package: "EMathicaFormulaDisplayKit")
            ],
            path: "Sources/EMathicaWorkspaceKit"
        ),
        .testTarget(
            name: "EMathicaWorkspaceKitTests",
            dependencies: [
                "EMathicaWorkspaceKit",
                .product(name: "EMathicaMathInputCore", package: "EMathicaMathInputKit"),
                .product(name: "EMathicaMathInputUI", package: "EMathicaMathInputKit")
            ],
            path: "Tests/EMathicaWorkspaceKitTests"
        )
    ]
)
