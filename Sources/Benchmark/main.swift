import Foundation
import Swiftkiq

var options = LaunchOptions()
options.connectionPool = 25
let router = Router()
LoggerInitializer.initialize(loglevel: .error, logfile: nil)

let q = DispatchQueue(label: "benchmark")
let start = Date()
q.async {
    let queue = Queue("default")
    while true {
        do {
            let count = try queue.count()
            Swiftkiq.logger.error("\(queue): \(count)")
            usleep(200000)
            if count == 0 {
                break
            }
        } catch {
        }
    }
    
    let duration = Date().timeIntervalSince(start)
    let throughput = 100000 / duration
    Swiftkiq.logger.error("Done in \(duration): \(throughput) jobs/sec")
    usleep(100000)
    exit(0)
}

CLI.start(router: router, launchOptions: options)
