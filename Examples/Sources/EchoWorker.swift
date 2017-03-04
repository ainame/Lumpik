import Swiftkiq

class EchoWorker: Worker {
    struct Args: Argument {
        public func toDictionary() -> [String: Any] {
            return [String: Any]()
        }

        static func from(_ dictionary: Dictionary<String, Any>) -> Args {
            return Args()
        }
    }
    var jid: String?
    var queue: Queue?
    var retry: Int?

    required init() {}

    func perform(_ args: Args) throws {
    }
}
