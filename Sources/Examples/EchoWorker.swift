import Foundation
import Swiftkiq

class EchoWorker: Worker {
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
        sleep(3)
    }
}
