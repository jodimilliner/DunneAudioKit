// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DunneAudioKit",
    platforms: [.macOS(.v12), .iOS(.v13), .tvOS(.v13)],
    products: [.library(name: "DunneAudioKit", targets: ["DunneAudioKit"])],
    dependencies: [
        .package(url: "https://github.com/AudioKit/KissFFT", from: "1.0.0"),
        .package(url: "https://github.com/AudioKit/AudioKit", from: "5.6.0"),
        .package(url: "https://github.com/AudioKit/AudioKitEX", from: "5.6.0"),
    ],
    targets: [
        .target(
            name: "DunneAudioKit", 
            // resources: [
            //     .process("click.wav"),
            //     .process("chordMapPop.json"),
            //     .process("chordMapJazz.json")
            // ],
            dependencies: ["AudioKit", "AudioKitEX", "CDunneAudioKit"]
        ),
        .target(
            name: "CDunneAudioKit",
            dependencies: ["AudioKit", "AudioKitEX", "KissFFT"],
            exclude: [
                "DunneCore/Sampler/Wavpack/license.txt",
                "DunneCore/Common/README.md",
                "DunneCore/Sampler/README.md",
                "DunneCore/README.md",
            ],
            cxxSettings: [.headerSearchPath("DunneCore/Common")]
        ),
        .testTarget(name: "DunneAudioKitTests", dependencies: ["DunneAudioKit"], resources: [.copy("TestResources/")]),
    ],
    cxxLanguageStandard: .cxx14
)
