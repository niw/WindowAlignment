// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WindowManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "WindowManager",
            targets: [
                "WindowManager"
            ]
        ),
    ],
    targets: [
        .target(
            name: "WindowManager",
            dependencies: [
                .target(
                    name: "Extern"
                )
            ]
        ),
        .target(
            name: "Extern",
            linkerSettings: [
                .unsafeFlags([
                    "-iframework", "/System/Library/PrivateFrameworks",
                    "-framework", "SkyLight"
                ])
            ]
        )
    ]
)
