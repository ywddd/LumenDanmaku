// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LumenDanmaku",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "LumenDanmaku", targets: ["LumenDanmaku"])
    ],
    targets: [
        .target(name: "LumenDanmaku")
    ]
)
