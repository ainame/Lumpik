import Foundation
import Swiftkiq

class EchoWorker: Worker {
    enum EchoWorkerError: Error {
        case randomError
    }

    struct Args: Argument {
        public var message: String
        public func toDictionary() -> [String: Any] {
            return ["message": message]
        }

        static func from(_ dictionary: Dictionary<String, Any>) -> Args {
            return Args(message: dictionary["message"] as! String)
        }
    }
    var jid: Jid?
    var queue: Queue?
    var retry: Int?

    required init() {}

    func perform(_ args: Args) throws {
        print(args.message)
        if Int(arc4random_uniform(UInt32(2))) == 0 {
            throw EchoWorkerError.randomError
        }
    }
}

class Router: Routable {
    func dispatch(_ work: UnitOfWork, errorCallback: WorkerFailureCallback) throws {
        switch work.workerType {
        case "EchoWorker":
            try invokeWorker(workerType: EchoWorker.self, work: work, errorCallback: errorCallback)
        default:
            break
        }
    }
}

let router = Router()
let options = LaunchOptions(
    concurrency: 2,
    queues: [Queue(rawValue: "default"), Queue(rawValue: "other")],
    router: router,
    daemonize: false
)

let launcher = Launcher(options: options)
launcher.run()

try EchoWorker.performAsync(.init(message: "aaa1"))
try EchoWorker.performAsync(.init(message: "aaa2"))
try EchoWorker.performAsync(.init(message: "aaa3"))
try EchoWorker.performAsync(.init(message: "aaa1"))
try EchoWorker.performAsync(.init(message: "aaa2"))
try EchoWorker.performAsync(.init(message: "aaa3"))

while true {
    sleep(1)
}
