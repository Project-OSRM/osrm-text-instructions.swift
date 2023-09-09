// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "osrm-text-instructions.swift",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v10_14), .iOS(.v12), .watchOS(.v5), .tvOS(.v12)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "OSRMTextInstructions",
            targets: ["OSRMTextInstructions"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "MapboxDirections", url: "https://github.com/mapbox/mapbox-directions-swift", from: "2.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "OSRMTextInstructions",
            dependencies: ["MapboxDirections"],
            path: "OSRMTextInstructions",
            exclude: ["Info.plist"]),
        .testTarget(
            name: "OSRMTextInstructionsTests",
            dependencies: [
                "OSRMTextInstructions",
                "MapboxDirections",
            ],
            path: "OSRMTextInstructionsTests",
            exclude: ["Info.plist"],
            resources: [
                // This uses a symlink since this is a user-managed submodule that is present in the root of the repo.
                // The symlink allows it to be referenced as if it's part of the `OSRMTextInstructionsTests` path.
                .copy("osrm-text-instructions"),
            ]),
    ]
)
