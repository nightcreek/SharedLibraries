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
            name: "EMathicaFormulaDisplayVendor",
            path: "Sources/EMathicaFormulaDisplayVendor",
            resources: [
                .copy("SwiftMath/mathFonts.bundle")
            ]
        ),
        .target(
            name: "EMathicaFormulaDisplayCore",
            dependencies: ["EMathicaFormulaDisplayVendor"],
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
        ),
        .testTarget(
            name: "VendorCompatibilityTests",
            dependencies: ["EMathicaFormulaDisplayVendor"],
            path: "Tests/VendorCompatibilityTests"
        ),
        .testTarget(
            name: "FormulaReadOnlyRenderingTests",
            dependencies: ["EMathicaFormulaDisplayCore", "EMathicaFormulaDisplaySwiftUI"],
            path: "Tests/FormulaReadOnlyRenderingTests"
        ),
        .testTarget(
            name: "FormulaFontRoleTests",
            dependencies: ["EMathicaFormulaDisplayCore"],
            path: "Tests/FormulaFontRoleTests"
        )
    ]
)
