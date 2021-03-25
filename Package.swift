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
        .binaryTarget(name: "BlueShift_iOS_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.1.16/BlueShift_iOS_SDK.xcframework.zip", checksum: "f0219d38dd85e0c19e548cefaa5257f601a4e50c38875dcfd65b8f1e33f1d08d"),
        .binaryTarget(name: "BlueShift_iOS_Extension_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.1.16/BlueShift_iOS_Extension_SDK.xcframework.zip", checksum: "985cbc624d5ed694a43807e769e00c0ef5e07f0117f11a1df5fb6082adc0e613"),
    ]
)
