// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Utilities",
    platforms: [
        .iOS(.v17) // или .iOS(.v17.0) — это одно и то же, .iOS(.v17.6) не требуется!
    ],
    products: [
        .library(name: "PieChart", targets: ["PieChart"]),
    ],
    targets: [
        .target(name: "PieChart", path: "Sources/PieChart"),
    ]
)
