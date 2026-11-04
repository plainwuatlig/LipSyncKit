// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LipSyncKit",
    platforms: [.iOS(.v16), .macOS(.v13), .visionOS(.v1)],
    products: [
        .library(name: "LipSyncKit", targets: ["LipSyncKit"]),
        .library(name: "LipSyncKitAVSpeech", targets: ["LipSyncKitAVSpeech"]),
    ],
    targets: [
        .target(name: "LipSyncKit"),
        .target(name: "LipSyncKitAVSpeech", dependencies: ["LipSyncKit"]),
        .testTarget(name: "LipSyncKitTests", dependencies: ["LipSyncKit"]),
        .testTarget(name: "LipSyncKitAVSpeechTests", dependencies: ["LipSyncKitAVSpeech"]),
    ]
)
