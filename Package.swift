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
        .binaryTarget(name: "BlueShift_iOS_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.2.1/BlueShift_iOS_SDK.xcframework.zip", checksum: "5afa48a1cbfde902383601df9a1285b8f16537f3605320e5987c12185dc47af6"),
        .binaryTarget(name: "BlueShift_iOS_Extension_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.2.1/BlueShift_iOS_Extension_SDK.xcframework.zip", checksum: "7bf832497c7ddf01daf12a56950624c1abe1f63df017030d93c9206a730a35f1"),
    ]
)
