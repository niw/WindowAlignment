// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WindowAlignment",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "HotKey",
            targets: [
                "HotKey"
            ]
        ),
        .library(
            name: "WindowManager",
            targets: [
                "WindowManager"
            ]
        ),
        .library(
            name: "WindowManagerExtension",
            targets: [
                "WindowManagerExtension"
            ]
        ),
    ],
    targets: [
        .target(
            name: "HotKey"
        ),
        .target(
            name: "WindowManager",
            dependencies: [
                .target(
                    name: "WindowManagerExtern"
                )
            ]
        ),
        .target(
            name: "WindowManagerExtern",
            linkerSettings: [
                .unsafeFlags([
                    "-iframework", "/System/Library/PrivateFrameworks",
                    "-framework", "SkyLight"
                ])
            ]
        ),
        .target(
            name: "WindowManagerExtension",
            dependencies: [
                .target(
                    name: "WindowManager"
                ),
                .target(
                    name: "WindowManagerExtern"
                )
            ]
        ),
    ]
)
