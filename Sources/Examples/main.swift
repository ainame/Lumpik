import Foundation
import Swiftkiq

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

let commandLine = CLI.makeCLI(options)
commandLine.start()
