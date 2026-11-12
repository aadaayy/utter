// swift-tools-version:5.9
// Utter's rules (cleanup, spacing, the hand-off between app and keyboard, the
// silence timer) as a small package, so the logic tests run anywhere Swift
// runs, including a cheap Linux machine. The app and keyboard are built from
// Utter.xcodeproj, which compiles these same files.
import PackageDescription

let package = Package(
    name: "UtterCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "UtterCore", targets: ["UtterCore"]),
    ],
    targets: [
        .target(name: "UtterCore", path: "Shared/Core"),
        .testTarget(name: "UtterCoreTests", dependencies: ["UtterCore"], path: "Tests/UtterCoreTests"),
    ]
)
