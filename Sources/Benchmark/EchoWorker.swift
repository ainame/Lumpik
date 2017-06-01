import Foundation
import Swiftkiq

class EchoWorker: Worker {
    struct Args: Argument {
        var message: String
    }
    var jid: Jid?
    var queue: Queue?
    var retry: Int?

    required init() {}

    func perform(_ args: Args) throws {
    }
}
