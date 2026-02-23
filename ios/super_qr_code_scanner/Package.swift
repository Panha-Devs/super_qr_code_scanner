// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "super_qr_code_scanner",
    platforms: [
        .iOS(.v12)
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
            url: "https://github.com/Panha-Devs/super_qr_code_scanner_artifacts/releases/download/v1.0.7/super_qr_code_scanner-ios.xcframework.zip",
            checksum: "cc87927174b36bb361e1f808d5a42b434f4374dc43aa81238ac3afe64336d89f"
        )
    ]
)