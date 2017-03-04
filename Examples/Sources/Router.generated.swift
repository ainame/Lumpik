// Generated using Sourcery 0.5.8 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation
import Swiftkiq

class Router: Routable {
    func dispatch(processorId: Int, work: UnitOfWork) throws {
        switch work.workerClass {
        case "EchoWorker":
            try invokeWorker(processorId: processorId, workerClass: EchoWorker.self, work: work)
        default:
            break
        }
    }
}
