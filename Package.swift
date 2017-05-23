import PackageDescription

let package = Package(
    name: "Swiftkiq",
    targets: [
    	Target(name: "Swiftkiq"),
        // uncomment if you want to build example
        // Target(name: "Examples", dependencies: ["Swiftkiq"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/vapor/redis.git", majorVersion: 2),
        .Package(url: "https://github.com/ainame/Swift-Daemon.git", majorVersion: 0),
        .Package(url: "https://github.com/lyft/mapper.git", majorVersion: 6),
        .Package(url: "https://github.com/IBM-Swift/BlueSignals.git", majorVersion: 0),
        .Package(url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git", majorVersion: 1),
        .Package(url: "https://github.com/kylef/Commander.git", majorVersion: 0),
    ],
    exclude: [
        // comment out if you want to build example
        "Sources/Examples",
    ]
)
