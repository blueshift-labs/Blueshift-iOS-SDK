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
        .binaryTarget(name: "BlueShift_iOS_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.1.14/BlueShift_iOS_SDK.xcframework.zip", checksum: "658186fcc319bba577a36282ee02998e5f9ecdcffdf8be495ccc13ece44daa55"),
        .binaryTarget(name: "BlueShift_iOS_Extension_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.1.14/BlueShift_iOS_Extension_SDK.xcframework.zip", checksum: "ec382d09fac5649bd61cf995ef331cb9c03553d593b472e5b000208bd482a008"),
    ]
)
