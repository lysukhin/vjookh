// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "vjookh",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "Core", resources: [.copy("Resources")]),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
    ]
)
