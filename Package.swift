// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BlueShift-iOS-SDK",
    platforms: [
            .iOS(.v9)
        ],
    products: [
        // Core SDK - Objective-C only, no Swift dependencies
        .library(
            name: "BlueShift_iOS_SDK",
            targets: ["BlueShift_iOS_SDK"]),
        // Optional SwiftUI support for in-app notifications (iOS 13.0+)
        .library(
            name: "BlueShift_iOS_SDK_SwiftUI",
            targets: ["BlueShift_iOS_SDK_SwiftUI"]),
        .library(
            name: "BlueShift_iOS_Extension_SDK",
            targets: ["BlueShift_iOS_Extension_SDK"]),
    ],
    dependencies: [],
    targets: [
        // Core SDK target - excludes SwiftUI directory to keep it Objective-C only
        .target(
            name: "BlueShift_iOS_SDK",
            dependencies: [],
            path: "BlueShift-iOS-SDK",
            exclude: ["SwiftUI"],
            resources: [
                .process("Resources"),
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("./"),
                .headerSearchPath("InApps/"),
                .headerSearchPath("Inbox/")
            ],
            linkerSettings: [
                .linkedFramework("CoreData"),
                .linkedFramework("CoreTelephony", .when(platforms: [.iOS])),
                .linkedFramework("UserNotifications"),
                .linkedFramework("WebKit")
            ]
        ),
        // SwiftUI target - optional add-on for SwiftUI-based in-app notifications
        .target(
            name: "BlueShift_iOS_SDK_SwiftUI",
            dependencies: ["BlueShift_iOS_SDK"],
            path: "BlueShift-iOS-SDK/SwiftUI",
            linkerSettings: [
                .linkedFramework("SwiftUI", .when(platforms: [.iOS])),
                .linkedFramework("WebKit", .when(platforms: [.iOS]))
            ]
        ),
        .target(
            name: "BlueShift_iOS_Extension_SDK",
            dependencies: [],
            path: "BlueShift-iOS-Extension-SDK",
            publicHeadersPath: "include"
        )
    ]
)
