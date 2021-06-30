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
        .binaryTarget(name: "BlueShift_iOS_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.1.20/BlueShift_iOS_SDK.xcframework.zip", checksum: "f6e7cd6b557403d370c5ca0324108638c33484d5cad547f8d6a2ce1326823d7b"),
        .binaryTarget(name: "BlueShift_iOS_Extension_SDK", url: "https://github.com/blueshift-labs/Blueshift-iOS-SDK/releases/download/2.1.20/BlueShift_iOS_Extension_SDK.xcframework.zip", checksum: "7638ef37a47466da9f15305315f16a78029d0814218ae66def66ef476d362e94"),
    ]
)
