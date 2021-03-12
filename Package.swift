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
        .binaryTarget(name: "BlueShift_iOS_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.1.15/BlueShift_iOS_SDK.xcframework.zip", checksum: "acede870954b04a043f2f5ff957e13d7869d45dccfd6fe577840bb2d7788b2fc"),
        .binaryTarget(name: "BlueShift_iOS_Extension_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.1.15/BlueShift_iOS_Extension_SDK.xcframework.zip", checksum: "e44eb3bf29712ab68e8e7fae866784cf47771b3f3dec896d3100409ced8f1108"),
    ]
)
