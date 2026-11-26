// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    
    // Genuin: every name is prefixed, so a host app that also uses stock prebid-mobile-ios through SPM
    // gets no duplicate target or module.
    name: "GenuinPrebidMobile",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "GenuinPrebidMobile",
            targets: ["GenuinPrebidMobile"]
        ),
        .library(
            name: "GenuinPrebidMobileAdMobAdapters",
            targets: ["GenuinPrebidMobileAdMobAdapters"]
        ),
        .library(
            name: "GenuinPrebidMobileGAMEventHandlers",
            targets: ["GenuinPrebidMobileGAMEventHandlers"]
        ),
        .library(
            name: "GenuinPrebidMobileMAXAdapters",
            targets: ["GenuinPrebidMobileMAXAdapters"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", .upToNextMajor(from: "13.0.0")),
        .package(url: "https://github.com/AppLovin/AppLovin-MAX-Swift-Package.git", .upToNextMajor(from: "13.0.0")),
    ],
    targets: [
        .target(
            name: "GenuinPrebidMobile",
            dependencies: [
                "GenuinPrebidMobileOMSDK",
            ],
            path: "PrebidMobile",
            sources: ["Swift"]
        ),
        .binaryTarget(
            name: "GenuinPrebidMobileOMSDK",
            path: "Frameworks/OMSDK_Prebidorg.xcframework"
        ),
        .target(
            name: "GenuinPrebidMobileAdMobAdapters",
            dependencies: [
                "GenuinPrebidMobile",
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "EventHandlers/PrebidMobileAdMobAdapters",
            sources: ["Sources"]
        ),
        .target(
            name: "GenuinPrebidMobileGAMEventHandlers",
            dependencies: [
                "GenuinPrebidMobile",
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "EventHandlers/PrebidMobileGAMEventHandlers",
            sources: ["Sources"]
        ),
        .target(
            name: "GenuinPrebidMobileMAXAdapters",
            dependencies: [
                "GenuinPrebidMobile",
                .product(name: "AppLovinSDK", package: "AppLovin-MAX-Swift-Package"),
            ],
            path: "EventHandlers/PrebidMobileMAXAdapters",
            sources: ["Sources"]
        ),
    ]
)
