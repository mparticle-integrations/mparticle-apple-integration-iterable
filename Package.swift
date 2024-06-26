// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mParticle-Iterable",
    platforms: [ .iOS(.v11) ],
    products: [
        .library(
            name: "mParticle-Iterable",
            targets: ["mParticle-Iterable"]),
    ],
    dependencies: [
      .package(name: "mParticle-Apple-SDK",
               url: "https://github.com/mParticle/mparticle-apple-sdk",
               .upToNextMajor(from: "8.19.0")),
      .package(name: "IterableSDK",
               url: "https://github.com/Iterable/swift-sdk",
               .upToNextMajor(from: "6.5.2")),
    ],
    targets: [
        .target(
            name: "mParticle-Iterable",
            dependencies: [
                .product(name: "mParticle-Apple-SDK", package: "mParticle-Apple-SDK"),
                .product(name: "IterableSDK", package: "IterableSDK"),
            ],
            path: "mParticle-Iterable",
            exclude: ["Info.plist"],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "."
        ),
    ]
)
