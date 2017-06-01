import Foundation
import Swiftkiq

var options = LaunchOptions()
options.connectionPool = 25
let router = Router()

let q = DispatchQueue(label: "benchmark")
q.async {
    let queue = Queue("default")
    let start = Date()
    while true {
        do {
            let count = try queue.count()
            print("\(queue): \(count)")
            usleep(200000)
            if count == 0 {
                break
            }
        } catch {
        }
    }
    
    let duration = Date().timeIntervalSince(start)
    let throughput = 100000 / duration
    print("Done in \(duration): \(throughput) jobs/sec")
    exit(0)
}

LoggerInitializer.initialize(loglevel: .error, logfile: nil)
CLI.start(router: router, launchOptions: options)
