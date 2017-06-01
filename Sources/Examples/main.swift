import Foundation
import Swiftkiq

var options = LaunchOptions()
options.connectionPool = 25
let router = Router()

let q = DispatchQueue(label: "benchmark")
q.async {
    while true {
        do {
            let queue = Queue("default")
            let count = try queue.count()
            print("\(queue): \(count)")
            usleep(50000)
            if count == 0 {
                break
            }
        } catch {
            // print(timeout)
        }
    }
    exit(0)
}

LoggerInitializer.initialize(loglevel: .error, logfile: nil)
CLI.start(router: router, launchOptions: options)
