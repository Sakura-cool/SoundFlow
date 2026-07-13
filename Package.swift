// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SoundFlow",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SoundFlow", targets: ["SoundFlow"])
    ],
    targets: [
        .executableTarget(
            name: "SoundFlow",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("CoreAudio"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("AudioToolbox")
            ]
        ),
        .testTarget(
            name: "SoundFlowTests",
            dependencies: ["SoundFlow"],
            path: "Tests",
            linkerSettings: [
                .linkedFramework("CoreAudio"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("AudioToolbox")
            ]
        )
    ]
)
