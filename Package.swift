// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BlueShift-iOS-SDK",
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
        .binaryTarget(name: "BlueShift_iOS_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.1.19/BlueShift_iOS_SDK.xcframework.zip", checksum: "01b0408dcbd509d3e7c1e1b8f3ebbd197109fd0a820ad0249296537fca1a0a2c"),
        .binaryTarget(name: "BlueShift_iOS_Extension_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.1.19/BlueShift_iOS_Extension_SDK.xcframework.zip", checksum: "8ec518d17e2e6f7e9f4f8770975775fe5ee9683d895f5ec5bab5e715b59e334e"),
    ]
)
