// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Slake",
  platforms: [.macOS(.v10_15)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "Slake",
      targets: ["Slake"]
    ),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    .package(url: "https://github.com/groue/CombineExpectations.git", from: "0.5.0"),
    .package(url: "https://github.com/apple/swift-tools-support-core.git", from: "0.1.12"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "Slake",
      dependencies: [
        .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
      ]
    ),
    .testTarget(
      name: "SlakeTests",
      dependencies: ["Slake", "CombineExpectations"]
    ),
  ]
)
