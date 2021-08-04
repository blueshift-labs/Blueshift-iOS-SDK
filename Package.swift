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
        .binaryTarget(name: "BlueShift_iOS_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.2.0/BlueShift_iOS_SDK.xcframework.zip", checksum: "a23c33a3929ea9db5bf564c91156228a15ca89eb986bedf102c70a639a45ce90"),
        .binaryTarget(name: "BlueShift_iOS_Extension_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.2.0/BlueShift_iOS_Extension_SDK.xcframework.zip", checksum: "0a0e40176b1e7569cc331657e8b26298dab3958e16485d98c60e8a4e22b24f3d"),
    ]
)
