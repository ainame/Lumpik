import PackageDescription

let package = Package(
    name: "Swiftkiq",
    dependencies: [
        .Package(url: "https://github.com/vapor/redbird.git", majorVersion: 0),
        .Package(url: "https://github.com/ainame/Swift-Daemon.git", majorVersion: 0),
        .Package(url: "https://github.com/lyft/mapper.git", majorVersion: 6),
        .Package(url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git", majorVersion: 1)
    ]
)
