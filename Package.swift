// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "objc",
    products: [
        .library(
            name: "objc",
            targets: ["objc"]),
    ],
    targets: [
        .target(name: "objc")
    ]
)
