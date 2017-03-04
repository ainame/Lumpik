import PackageDescription

let package = Package(
    name: "Swiftkiq",
    dependencies: [
        .Package(url: "https://github.com/vapor/redbird.git", majorVersion: 1, minor: 0),
        .Package(url: "https://github.com/ainame/Swift-Daemon.git", majorVersion: 0)
    ]
)
