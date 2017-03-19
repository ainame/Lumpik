import PackageDescription

let package = Package(
    name: "Swiftkiq",
    dependencies: [
        .Package(url: "https://github.com/vapor/redbird.git", Version("2.0.0-alpha.1")!),
        .Package(url: "https://github.com/ainame/Swift-Daemon.git", majorVersion: 0),
        .Package(url: "https://github.com/lyft/mapper.git", majorVersion: 6)
    ]
)
