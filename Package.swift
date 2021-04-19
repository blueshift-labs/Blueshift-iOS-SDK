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
        .binaryTarget(name: "BlueShift_iOS_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.1.17/BlueShift_iOS_SDK.xcframework.zip", checksum: "a60bd1fb5f0df698e90283c7f0a45aff95afb9c36978b64e9a9b3ab71bc8fd62"),
        .binaryTarget(name: "BlueShift_iOS_Extension_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.1.17/BlueShift_iOS_Extension_SDK.xcframework.zip", checksum: "02b74121a1a12ced145edd752f1a497ceef3bba0211fc8ca5439eacfcbd88491"),
    ]
)
