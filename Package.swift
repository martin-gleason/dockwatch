// swift-tools-version:5.9
// Created: 2026-10-18 11:25 -05:00 · Edited: 2026-10-18 11:25 -05:00
import PackageDescription

let package = Package(
    name: "DockWatch",
    platforms: [.macOS(.v14)],
    targets: [
        // Everything that talks to IOKit, DiskArbitration and power management.
        // No AppKit (NFR7), so it is tested headless.
        .target(name: "DockCore", path: "Sources/DockCore"),
        // The menu bar app. Thin: renders DockCore state and forwards clicks.
        .executableTarget(name: "DockWatch", dependencies: ["DockCore"], path: "Sources/DockWatch"),
        .testTarget(name: "DockCoreTests", dependencies: ["DockCore"], path: "Tests/DockCoreTests"),
    ]
)
