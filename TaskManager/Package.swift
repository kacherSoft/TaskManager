// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TaskManager",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "TaskManager", targets: ["TaskManager"])
    ],
    dependencies: [
        .package(path: "../TaskManagerUIComponents"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
        .package(url: "https://github.com/google/generative-ai-swift", from: "0.5.0")
    ],
    targets: [
        .executableTarget(
            name: "TaskManager",
            dependencies: [
                "TaskManagerUIComponents",
                "KeyboardShortcuts",
                .product(name: "GoogleGenerativeAI", package: "generative-ai-swift")
            ]
        )
    ]
)
