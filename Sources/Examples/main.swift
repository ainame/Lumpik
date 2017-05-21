import Foundation
import Swiftkiq

LoggerInitializer.initialize()
let router = Router()
let options = LaunchOptions(
    concurrency: 25,
    queues: [Queue(rawValue: "default"), Queue(rawValue: "other")],
    router: router,
    daemonize: false
)

let launcher = Launcher.makeLauncher(options: options)
let commandLine = CLI.makeCLI(launcher: launcher)
commandLine.start()
