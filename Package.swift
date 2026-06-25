// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Muzeebra",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "Muzeebra", targets: ["Muzeebra"]),
    ],
    targets: [
        .executableTarget(
            name: "Muzeebra",
            path: "Sources/Muzeebra"
        )
    ]
)
