// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "super_qr_code_scanner",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "super-qr-code-scanner",
            targets: ["super_qr_code_scanner"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "super_qr_code_scanner",
            url: "https://github.com/Panha-Devs/super_qr_code_scanner_artifacts/releases/download/v1.0.6/super_qr_code_scanner-macos.xcframework.zip",
            checksum: "64383b71ebac001f7eeb6a0170d2e28a2b4c84677619fc94f9fedd84430c5452"
        )
    ]
)