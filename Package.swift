// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "everydayFights", platforms: [.macOS(.v13)], products: [.executable(name: "everydayFights", targets: ["everydayFights"])], targets: [.target(name: "FightsCore"), .executableTarget(name: "everydayFights", dependencies: ["FightsCore"]), .testTarget(name: "FightsCoreTests", dependencies: ["FightsCore"])])
