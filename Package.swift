// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LipSyncKit",
    platforms: [.iOS(.v16), .macOS(.v13), .visionOS(.v1)],
    products: [
        .library(name: "LipSyncKit", targets: ["LipSyncKit"]),
    ],
    targets: [
        .target(name: "LipSyncKit"),
        .testTarget(name: "LipSyncKitTests", dependencies: ["LipSyncKit"]),
    ]
)
