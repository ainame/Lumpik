import Swiftkiq

class EchoWorker: WorkerType {
    struct Argument: ArgumentType {
        let message: String

        static func from(_ dictionary: Dictionary<String, Any>) -> Argument {
            return Argument(
                message: dictionary["message"]! as! String
            )
        }
    }
    var jid: String?
    var queue: Queue?
    var retry: Int?

    required init() {}

    func perform(_ argument: Argument) throws {
        print(argument.message)
    }
}
