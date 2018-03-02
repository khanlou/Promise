// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Promise",
    products: [
      .library(
        name: "Promise",
        targets: ["Promise"]
      ),
    ],
    dependencies: [],
    targets: [
      .target(
        name: "Promise",
        dependencies: [],
        path: "Promise"
      ),
      .testTarget(
        name: "PromiseTests", 
        dependencies: ["Promise"]
      )

    ]
)
