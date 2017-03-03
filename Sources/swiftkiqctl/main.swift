import Foundation
import Swiftkiq

let router = Router()
let options = LaunchOptions(
    concurrency: 25,
    queues: [Queue(rawValue: "default")],
    strategy: nil,
    router: router
)

let launcher = Launcher(options: options)
launcher.run()

let group = DispatchGroup()
group.enter()
group.wait()
