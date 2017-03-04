import PackageDescription

let package = Package(
    name: "swiftkiq_example",
    dependencies: [
        .Package(url: "../../Swiftkiq", majorVersion: 0)
    ]
)
