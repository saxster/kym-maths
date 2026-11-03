// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KymMaths",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(name: "KymMaths", targets: ["KymMaths"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.0"),
        .package(path: "../../teaching_kit")
    ],
    targets: [
        .executableTarget(
            name: "KymMaths",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "KymDesign", package: "teaching_kit"),
                .product(name: "KymLearning", package: "teaching_kit")
            ],
            path: "KymMaths",
            exclude: [
                "Info-iPad.plist",
                "KymMaths.entitlements",
                "KymMaths-iPad.entitlements"
            ],
            resources: [
                .copy("Resources/ContentPacks"),
                .copy("Resources/PatternedWorldBook")
            ]
        ),
        .testTarget(
            name: "KymMathsTests",
            dependencies: [
                "KymMaths",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Tests"
        )
    ]
)
