import PackageDescription

let package = Package(
    name: "Lumpik",
    targets: [
    	Target(name: "Lumpik"),
        // uncomment if you want to build example
        // Target(name: "Examples", dependencies: ["Lumpik"]),
        // Target(name: "Benchmark", dependencies: ["Lumpik"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/vapor/redis.git", majorVersion: 2),
        .Package(url: "https://github.com/ainame/Swift-Daemon.git", majorVersion: 0),
        .Package(url: "https://github.com/IBM-Swift/BlueSignals.git", majorVersion: 0),
        .Package(url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git", majorVersion: 1),
        .Package(url: "https://github.com/kylef/Commander.git", majorVersion: 0),
        .Package(url: "https://github.com/jpsim/Yams.git", majorVersion: 0)
    ],
    exclude: [
        // comment out if you want to build example
        "Sources/Examples",
        "Sources/Benchmark",
    ]
)
