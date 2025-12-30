// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "BagistoNative_iOS",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "BagistoNative_iOS", targets: ["BagistoNative_iOS"])
    ],
    dependencies: [
        .package(url: "https://github.com/hotwired/hotwire-native-ios.git", from: "1.2.1")
    ],
    targets: [
        .target(
            name: "BagistoNative_iOS",
            dependencies: [
                .product(name: "HotwireNative", package: "hotwire-native-ios")
            ]
        ),
        .testTarget(
            name: "BagistoNative_iOSTests",
            dependencies: ["BagistoNative_iOS"]
        )
    ]
)
