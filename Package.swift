import PackageDescription

let package = Package(
    name: "Swiftkiq",
    dependencies: [
        .Package(url: "https://github.com/ainame/Kitura-redis.git", Version(1, 6, 1)),
        .Package(url: "https://github.com/ainame/Swift-Daemon.git", majorVersion: 0)
    ]
)
