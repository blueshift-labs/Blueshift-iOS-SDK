// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BlueShift-iOS-SDK",
    platforms: [
            .iOS(.v9)
        ],
    products: [
        .library(
            name: "BlueShift_iOS_SDK",
            targets: ["BlueShift_iOS_SDK"]),
        .library(
            name: "BlueShift_iOS_Extension_SDK",
            targets: ["BlueShift_iOS_Extension_SDK"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BlueShift_iOS_SDK",
            dependencies: [],
            path: "BlueShift-iOS-SDK",
            resources: [
                .process("BlueShiftSDKDataModel.xcdatamodeld")
            ],  
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("./"),
                .headerSearchPath("InApps/")
            ],
            linkerSettings: [
                .linkedFramework("CoreData"),
                .linkedFramework("CoreTelephony", .when(platforms: [.iOS])),
                .linkedFramework("UserNotifications"),
                .linkedFramework("WebKit")
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
