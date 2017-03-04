import Foundation
import Swiftkiq

let router = Router()
let options = LaunchOptions(
    concurrency: 25,
    queues: [Queue(rawValue: "default"), Queue(rawValue: "other")],
    router: router,
    daemonize: false
)

let launcher = Launcher(options: options)
launcher.run()
while true {
    sleep(1)
}
