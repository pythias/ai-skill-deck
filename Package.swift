// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "SkillDeck",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "SkillDeck",
            targets: ["SkillDeck"]
        )
    ],
    targets: [
        .executableTarget(
            name: "SkillDeck",
            dependencies: [],
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit")
            ]
        )
    ]
)
