import PackageDescription

let package = Package(
    name: "Swiftkiq",
    targets: [
        Target(name: "Swiftkiq"),
        Target(name: "swiftkiqctl",
            dependencies: [
                .Target(name: "Swiftkiq")
            ]
        )
    ],
    dependencies: [
        .Package(url: "https://github.com/vapor/redbird.git", majorVersion: 1, minor: 0),
        .Package(url: "https://github.com/DanToml/Jay.git", majorVersion: 1),
        .Package(url: "https://github.com/ainame/Swift-Daemon.git", majorVersion: 0)
    ]
)
