// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SonyConnect",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "SonyConnect",
            path: "Sources/SonyConnect",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOBluetooth"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("Foundation"),
            ]
        )
    ]
)
