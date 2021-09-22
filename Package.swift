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
        .binaryTarget(name: "BlueShift_iOS_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.2.2/BlueShift_iOS_SDK.xcframework.zip", checksum: "e29d6c0e63b828045823f9de7602436d3cef72f5c112ce91fa8ba4fcc4e05161"),
        .binaryTarget(name: "BlueShift_iOS_Extension_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.2.2/BlueShift_iOS_Extension_SDK.xcframework.zip", checksum: "3a2b89c149711dbc56ba29fe2e83b38391e7b5373c12c8adb3bf3ad1d1aa8f24"),
    ]
)
