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
    dependencies: [
        .package(path: "../EMathicaFormulaDisplayKit"),
        .package(path: "../EMathicaThemeKit")
    ],
    targets: [
        .target(
            name: "EMathicaMathInputCore",
            dependencies: []
        ),
        .target(
            name: "EMathicaMathInputUI",
            dependencies: [
                "EMathicaMathInputCore",
                .product(name: "EMathicaFormulaDisplayCore", package: "EMathicaFormulaDisplayKit"),
                .product(name: "EMathicaFormulaDisplaySwiftUI", package: "EMathicaFormulaDisplayKit"),
                "EMathicaThemeKit"
            ]
        ),
        .testTarget(
            name: "EMathicaMathInputCoreTests",
            dependencies: ["EMathicaMathInputCore"]
        ),
        .testTarget(
            name: "EMathicaMathInputUITests",
            dependencies: ["EMathicaMathInputUI"]
        )
    ]
)
