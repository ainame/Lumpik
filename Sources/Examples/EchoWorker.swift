import Foundation
import Swiftkiq

class EchoWorker: Worker {
    struct Args: Argument {
        public var message: String
        
        public func toArray() -> [Any] {
            return [message]
        }

        static func from(_ array: [Any]) -> Args {
            return Args(message: array[0] as! String)
        }
    }
    var jid: Jid?
    var queue: Queue?
    var retry: Int?

    required init() {}

    func perform(_ args: Args) throws {
        print(args.message)
        sleep(3)
    }
}
