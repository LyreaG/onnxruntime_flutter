// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "onnxruntime_flutter",
  platforms: [
    .macOS("10.15")
  ],
  products: [
    .library(name: "onnxruntime-flutter", targets: ["onnxruntime_flutter"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "onnxruntime_flutter",
      dependencies: ["onnxruntime"]
    ),
    // libonnxruntime.1.22.0.dylib (universal2) from the release, wrapped as a
    // framework so Swift Package Manager can embed it in the app.
    .binaryTarget(
      name: "onnxruntime",
      url: "https://github.com/LyreaG/onnxruntime_flutter/releases/download/onnxruntime-1.22.0/onnxruntime-macos-1.22.0.xcframework.zip",
      checksum: "fa3183161c5d6120b9eec5cdb317a2d370eda5174d477bf7c23802c9c783c9df"
    ),
  ]
)
