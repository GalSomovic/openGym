// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OpenGymCore",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [.library(name: "OpenGymCore", targets: ["OpenGymCore"])],
    targets: [
        .target(name: "OpenGymCore", resources: [.copy("Resources/engine.js")]),
        .testTarget(name: "OpenGymCoreTests", dependencies: ["OpenGymCore"]),
    ]
)
