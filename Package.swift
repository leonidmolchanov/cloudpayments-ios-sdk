// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "CloudpaymentsSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Cloudpayments",
            targets: ["Cloudpayments"]
        ),
        .library(
            name: "CloudpaymentsNetworking",
            targets: ["CloudpaymentsNetworking"]
        )
    ],
    targets: [
        .target(
            name: "Cloudpayments",
            dependencies: [
                "CloudpaymentsNetworking"
            ],
            path: "sdk",
            exclude: [
                "Pods",
                "sdk-Bridging-Header.h"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "CloudpaymentsNetworking",
            path: "networking",
            sources: ["source"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
