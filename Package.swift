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
        .binaryTarget(name: "BlueShift_iOS_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.1.18.1/BlueShift_iOS_SDK.xcframework.zip", checksum: "ab5112b965f0498bd211ef7b1bcd4810e1aa8aa07bafd2309c09032b2bf7aff4"),
        .binaryTarget(name: "BlueShift_iOS_Extension_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.1.18.1/BlueShift_iOS_Extension_SDK.xcframework.zip", checksum: "d7b2d90de6af349239be2bbc6aaeb8e8d9156a761f02ea8798f9bda47af92147"),
    ]
)
