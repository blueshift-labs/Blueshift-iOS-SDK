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
        .binaryTarget(name: "BlueShift_iOS_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.1.18/BlueShift_iOS_SDK.xcframework.zip", checksum: "79ac16cf8593493497743a2506b02fcdd3bb637ad2121d9a7ef213f3681cd865"),
        .binaryTarget(name: "BlueShift_iOS_Extension_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.1.18/BlueShift_iOS_Extension_SDK.xcframework.zip", checksum: "8be874c92a76b2160671dfab393cead4cde1740c0b32ad58c4fb48bc25831742"),
    ]
)
