// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xml-coding",
    products: [
        .library(name: "XMLCoding", targets: ["XMLCoding"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "XMLCoding", dependencies: []),
        .testTarget(name: "XMLCodingTests", dependencies: ["XMLCoding"]),
    ]
)
