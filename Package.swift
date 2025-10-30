// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Libs",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "CoredataWrapperLib",
            targets: ["CoredataWrapperLib"]),
        .library(
            name: "CommonUtils",
            targets: ["CommonUtils"]),
    ],
    targets: [
        .target(
            name: "CoredataWrapperLib",
            path: "CoredataWrapperLib/Sources"
        ),
        .target(
            name: "CommonUtils",
            path: "CommonUtils/Sources"
        )
    ]
)
