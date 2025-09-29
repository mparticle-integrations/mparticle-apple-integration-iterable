// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let noLocation = "-NoLocation"
let mpIterable = "mParticle-Iterable"
let mpIterableNoLocation = mpIterable + noLocation

// MARK: - External Packages
let mpSDK = "mParticle-Apple-SDK"
let mpSDKNoLocation = mpSDK + noLocation
let iterableSDK = "IterableSDK"

let package = Package(
    name: mpIterable,
    platforms: [ .iOS(.v11) ],
    products: [
        .library(
            name: mpIterable,
            targets: [mpIterable]),
    ],
    dependencies: [
      .package(name: mpSDK,
               url: "https://github.com/mParticle/mparticle-apple-sdk",
               .upToNextMajor(from: "8.19.0")),
      .package(name: iterableSDK,
               url: "https://github.com/Iterable/swift-sdk",
               .upToNextMajor(from: "6.5.2")),
    ],
    targets: [
        .target(
            name: mpIterable,
            dependencies: [
                .product(name: mpSDK, package: mpSDK),
                .product(name: iterableSDK, package: iterableSDK),
                .product(name: "IterableAppExtensions", package: iterableSDK)
            ],
            path: "mParticle-iterable",
            exclude: ["Info.plist"],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "."
        ),
        .target(
            name: mpIterableNoLocation,
            dependencies: [
                .product(name: mpSDKNoLocation, package: mpSDK),
                .product(name: iterableSDK, package: iterableSDK),
                .product(name: "IterableAppExtensions", package: iterableSDK)
            ],
            path: "mParticle-iterable-NoLocation",
            exclude: ["Info.plist"],
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: ".",
            cSettings: [.define("MP_NO_LOCATION")]
        ),
    ]
)
