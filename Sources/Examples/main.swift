import Foundation
import Swiftkiq

LoggerInitializer.initialize()
let router = Router()
let options = LaunchOptions(
    concurrency: 25,
    queues: [
        Queue("default"),
        Queue("other"),
        Queue("complex")
    ],
    router: router,
    daemonize: false,
    connectionPool: 25
)

let launcher = Launcher.makeLauncher(options: options)
let commandLine = CLI.makeCLI(launcher: launcher)
commandLine.start()
