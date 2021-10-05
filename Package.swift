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
        .binaryTarget(name: "BlueShift_iOS_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.2.3/BlueShift_iOS_SDK.xcframework.zip", checksum: "f4bdfdc598abf03defaf1a4289d45d5194786732a35d0f0ed76891285fe5925a"),
        .binaryTarget(name: "BlueShift_iOS_Extension_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.2.3/BlueShift_iOS_Extension_SDK.xcframework.zip", checksum: "60be5392b71a7b489d281c122d4df62092caa21c1cbfb6c444736d1b95f181d2"),
    ]
)
