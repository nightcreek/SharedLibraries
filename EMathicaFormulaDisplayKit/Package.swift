// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EMathicaFormulaDisplayKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "EMathicaFormulaDisplayCore",
            targets: ["EMathicaFormulaDisplayCore"]
        ),
        .library(
            name: "EMathicaFormulaDisplaySwiftUI",
            targets: ["EMathicaFormulaDisplaySwiftUI"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "EMathicaFormulaDisplayCore",
            path: "Sources/EMathicaFormulaDisplayCore"
        ),
        .target(
            name: "EMathicaFormulaDisplaySwiftUI",
            dependencies: ["EMathicaFormulaDisplayCore"],
            path: "Sources/EMathicaFormulaDisplaySwiftUI"
        ),
        .testTarget(
            name: "EMathicaFormulaDisplayCoreTests",
            dependencies: ["EMathicaFormulaDisplayCore"],
            path: "Tests/EMathicaFormulaDisplayCoreTests"
        ),
        .testTarget(
            name: "EMathicaFormulaDisplaySwiftUITests",
            dependencies: ["EMathicaFormulaDisplaySwiftUI"],
            path: "Tests/EMathicaFormulaDisplaySwiftUITests"
        )
    ]
)
