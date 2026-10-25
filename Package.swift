// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Clipboard",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "ClipboardApp", path: "Sources/ClipboardApp")
    ]
)
