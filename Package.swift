// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VPN Connect",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "VPN Connect",
            dependencies: [],
            path: "src",
            linkerSettings: [
                .unsafeFlags(["-framework", "Cocoa", "-framework", "NetworkExtension", "-framework", "SwiftUI"])
            ]
        )
    ]
)
