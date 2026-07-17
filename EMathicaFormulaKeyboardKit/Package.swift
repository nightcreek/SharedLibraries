// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EMathicaFormulaKeyboardKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "EMathicaFormulaKeyboardCore",
            targets: ["EMathicaFormulaKeyboardCore"]
        ),
        .library(
            name: "EMathicaFormulaKeyboardBuiltin",
            targets: ["EMathicaFormulaKeyboardBuiltin"]
        ),
        .library(
            name: "EMathicaFormulaKeyboardRendering",
            targets: ["EMathicaFormulaKeyboardRendering"]
        ),
        .library(
            name: "EMathicaFormulaKeyboardSwiftUI",
            targets: ["EMathicaFormulaKeyboardSwiftUI"]
        )
    ],
    dependencies: [
        .package(path: "../EMathicaFormulaDisplayKit"),
        .package(path: "../EMathicaThemeKit")
    ],
    targets: [
        .target(
            name: "EMathicaFormulaKeyboardCore",
            dependencies: []
        ),
        .target(
            name: "EMathicaFormulaKeyboardBuiltin",
            dependencies: [
                "EMathicaFormulaKeyboardCore"
            ]
        ),
        .target(
            name: "EMathicaFormulaKeyboardRendering",
            dependencies: [
                "EMathicaFormulaKeyboardCore",
                .product(
                    name: "EMathicaFormulaDisplayCore",
                    package: "EMathicaFormulaDisplayKit"
                )
            ]
        ),
        .target(
            name: "EMathicaFormulaKeyboardSwiftUI",
            dependencies: [
                "EMathicaFormulaKeyboardCore",
                "EMathicaFormulaKeyboardRendering",
                .product(
                    name: "EMathicaFormulaDisplaySwiftUI",
                    package: "EMathicaFormulaDisplayKit"
                ),
                .product(
                    name: "EMathicaThemeKit",
                    package: "EMathicaThemeKit"
                )
            ]
        ),
        .testTarget(
            name: "EMathicaFormulaKeyboardCoreTests",
            dependencies: [
                "EMathicaFormulaKeyboardCore"
            ]
        ),
        .testTarget(
            name: "EMathicaFormulaKeyboardBuiltinTests",
            dependencies: [
                "EMathicaFormulaKeyboardBuiltin"
            ]
        ),
        .testTarget(
            name: "EMathicaFormulaKeyboardRenderingTests",
            dependencies: [
                "EMathicaFormulaKeyboardRendering"
            ]
        ),
        .testTarget(
            name: "EMathicaFormulaKeyboardSwiftUITests",
            dependencies: [
                "EMathicaFormulaKeyboardSwiftUI"
            ]
        )
    ]
)
