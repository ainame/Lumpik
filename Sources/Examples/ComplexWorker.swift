//
//  ComplexWorker.swift
//  Lumpik
//
//  Created by Namai Satoshi on 2017/05/21.
//
//

import Foundation
import Lumpik

class BaseWorker {
    var jid: Jid?
    var queue: Queue? = Queue("default")
    var retry: Int? = 25

    required init() {}
}

final class ComplexWorker: BaseWorker, Worker {
    struct Args: Argument {
        let userId: Int
        let comment: String
        // let data: [String: Any]
    }

    static var defaultQueue = Queue("complex")

    func perform(_ args: Args) throws {
        print("userId: \(args.userId), comment:\(args.comment), data:(args.data)")
        sleep(3)
    }
}
